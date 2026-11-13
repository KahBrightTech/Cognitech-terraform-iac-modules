mock_provider "aws" {
  override_during = plan
  mock_data "aws_caller_identity" {
    defaults = { account_id = "123456789012" }
  }
  mock_data "aws_region" {
    defaults = { name = "us-east-1" }
  }
  mock_data "aws_iam_roles" {
    defaults = { arns = [] }
  }
  mock_resource "aws_eks_cluster" {
    defaults = {
      arn                   = "arn:aws:eks:us-east-1:123456789012:cluster/identity-test"
      certificate_authority = [{ data = "dGVzdA==" }]
      identity = [{
        oidc = [{ issuer = "https://oidc.eks.us-east-1.amazonaws.com/id/TEST" }]
      }]
    }
  }
  mock_resource "aws_iam_openid_connect_provider" {
    defaults = {
      arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/TEST"
    }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::123456789012:role/mock-service-account" }
  }
  mock_resource "aws_iam_policy" {
    defaults = { arn = "arn:aws:iam::123456789012:policy/mock-service-account" }
  }
}

mock_provider "kubernetes" {
  override_during = plan
}
mock_provider "helm" {}
mock_provider "kubectl" {}
mock_provider "tls" {}

variables {
  common = {
    global        = false
    tags          = {}
    account_name  = "test"
    region_prefix = "use1"
  }
  eks = {
    key                     = "identity-test"
    name                    = "identity-test"
    role_arn                = "arn:aws:iam::123456789012:role/cluster"
    subnet_ids              = ["subnet-12345678", "subnet-87654321"]
    oidc_thumbprint         = "0123456789012345678901234567890123456789"
    create_service_accounts = true
    compute                 = { eks_node_groups = [] }
    service_accounts = [
      {
        name      = "healthpath-secrets"
        namespace = "healthpath"
        identity  = "pod_identity"
        policy    = "tests/fixtures/service-account-policy.yaml"
      },
      {
        name      = "infogrid-s3"
        namespace = "infogrid"
        policy    = "tests/fixtures/service-account-policy.json"
      }
    ]
  }
}

run "mixed_identities" {
  command = plan

  assert {
    condition = (
      output.eks_service_accounts["healthpath-healthpath-secrets"].identity == "pod_identity" &&
      output.eks_service_accounts["infogrid-infogrid-s3"].identity == "irsa" &&
      length(module.iam_roles) == 2 &&
      length(aws_eks_pod_identity_association.pia) == 1 &&
      length(aws_eks_addon.pod_identity_agent) == 1
    )
    error_message = "Both identities must create roles; only Pod Identity creates an association and enables the agent."
  }
  assert {
    condition = (
      aws_eks_pod_identity_association.pia["healthpath-healthpath-secrets"].namespace == "healthpath" &&
      aws_eks_pod_identity_association.pia["healthpath-healthpath-secrets"].service_account == "healthpath-secrets" &&
      aws_eks_pod_identity_association.pia["healthpath-healthpath-secrets"].role_arn == output.eks_service_accounts["healthpath-healthpath-secrets"].role_arn &&
      module.iam_roles["healthpath-healthpath-secrets"].aws_iam_policy_name == "test-use1-identity-test-healthpath-healthpath-secrets-policy" &&
      module.iam_roles["infogrid-infogrid-s3"].aws_iam_policy_name == "test-use1-identity-test-infogrid-infogrid-s3-policy"
    )
    error_message = "The association must bind the selected service account and role, and both YAML and JSON policies must be created."
  }
}

run "legacy_references" {
  command = plan
  variables {
    eks = {
      key                     = "identity-test"
      name                    = "identity-test"
      role_arn                = "arn:aws:iam::123456789012:role/cluster"
      subnet_ids              = ["subnet-12345678", "subnet-87654321"]
      oidc_thumbprint         = "0123456789012345678901234567890123456789"
      create_service_accounts = true
      compute                 = { eks_node_groups = [] }
      enable_eks_pia          = true
      service_accounts = [
        { key = "legacy-irsa", name = "legacy-irsa", role_key = "existing" },
        { key = "legacy-pia", name = "legacy-pia" }
      ]
      iam_roles = [{
        key                       = "existing"
        name                      = "existing"
        service_account_namespace = "default"
        service_account_name      = "legacy-irsa"
        create_custom_policy      = false
      }]
      eks_pia = [{
        key                       = "legacy-pia"
        service_account_namespace = "default"
        service_account_keys      = ["legacy-pia"]
        role_arn                  = "arn:aws:iam::123456789012:role/existing-pia"
      }]
    }
  }
  assert {
    condition = (
      length(module.iam_roles) == 1 &&
      output.eks_service_accounts["legacy-irsa"].role_arn == module.iam_roles["existing"].iam_role_arn &&
      output.eks_service_accounts["legacy-pia"].identity == "pod_identity" &&
      aws_eks_pod_identity_association.pia["legacy-pia"].role_arn == "arn:aws:iam::123456789012:role/existing-pia"
    )
    error_message = "Legacy role references and Pod Identity associations must retain their keys and must not create additional roles."
  }
}

run "pia_alias_and_default_irsa" {
  command = plan
  variables {
    eks = {
      key                     = "identity-test"
      name                    = "identity-test"
      role_arn                = "arn:aws:iam::123456789012:role/cluster"
      subnet_ids              = ["subnet-12345678", "subnet-87654321"]
      oidc_thumbprint         = "0123456789012345678901234567890123456789"
      create_service_accounts = true
      compute                 = { eks_node_groups = [] }
      service_accounts = [{
        name      = "secrets"
        namespace = "default"
        identity  = "pia"
        policy    = "tests/fixtures/service-account-policy.yaml"
        }, {
        name = "no-permissions"
      }]
    }
  }
  assert {
    condition = (
      module.iam_roles["default-secrets"].aws_iam_role_name == "test-use1-identity-test-default-secrets-role" &&
      module.iam_roles["default-secrets"].aws_iam_policy_name == "test-use1-identity-test-default-secrets-policy" &&
      module.iam_roles["default-no-permissions"].iam_policy_arn == null &&
      output.eks_service_accounts["default-no-permissions"].identity == "irsa" &&
      output.eks_service_accounts["default-secrets"].identity == "pod_identity" &&
      length(aws_eks_pod_identity_association.pia) == 1 &&
      length(aws_eks_addon.pod_identity_agent) == 1
    )
    error_message = "PIA must be an alias for Pod Identity, while omitted identity creates an IRSA role."
  }
}

run "disabled_service_accounts" {
  command = plan
  variables {
    eks = {
      key                     = "identity-test"
      name                    = "identity-test"
      role_arn                = "arn:aws:iam::123456789012:role/cluster"
      subnet_ids              = ["subnet-12345678", "subnet-87654321"]
      oidc_thumbprint         = "0123456789012345678901234567890123456789"
      create_service_accounts = false
      compute                 = { eks_node_groups = [] }
      service_accounts = [{
        name     = "disabled"
        identity = "pod_identity"
        policy   = "tests/fixtures/service-account-policy.yaml"
      }]
    }
  }
  assert {
    condition = (
      length(module.service_account) == 0 &&
      length(module.iam_roles) == 0 &&
      length(aws_eks_pod_identity_association.pia) == 0 &&
      length(aws_eks_addon.pod_identity_agent) == 0
    )
    error_message = "Disabling service accounts must also disable their automatic IAM roles and Pod Identity resources."
  }
}

run "invalid_identity" {
  command = plan
  variables {
    eks = {
      key             = "identity-test"
      name            = "identity-test"
      role_arn        = "arn:aws:iam::123456789012:role/cluster"
      subnet_ids      = ["subnet-12345678", "subnet-87654321"]
      oidc_thumbprint = "0123456789012345678901234567890123456789"
      compute         = { eks_node_groups = [] }
      service_accounts = [{
        name     = "invalid"
        identity = "invalid"
      }]
    }
  }
  expect_failures = [var.eks]
}

run "awx_operator_without_iam_role" {
  command = plan
  variables {
    eks = {
      key             = "identity-test"
      name            = "identity-test"
      role_arn        = "arn:aws:iam::123456789012:role/cluster"
      subnet_ids      = ["subnet-12345678", "subnet-87654321"]
      oidc_thumbprint = "0123456789012345678901234567890123456789"
      compute = {
        create_node_group = true
        eks_node_groups   = []
        key_pair = {
          name        = "identity-test"
          secret_name = "identity-test-key"
        }
      }
      addons = {
        awx_operator = { enabled = true }
      }
    }
  }
  assert {
    condition = (
      length(module.iam_roles) == 0 &&
      length(helm_release.awx_operator) == 1 &&
      length(yamldecode(helm_release.awx_operator[0].values[0]).serviceAccount.annotations) == 0
    )
    error_message = "The AWX operator must deploy without an IAM role or a null role annotation."
  }
}

run "yaml_policy_document" {
  command = plan
  module {
    source = "./IAM-Roles"
  }
  variables {
    iam_role = {
      key                = "yaml-policy"
      name               = "yaml-policy"
      assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
      policy = {
        name         = "yaml-policy"
        policy       = "tests/fixtures/service-account-policy.yaml"
        cluster_name = "identity-test"
      }
    }
  }
  assert {
    condition = (
      jsondecode(aws_iam_policy.policy[0].policy).Statement[0].Action == "secretsmanager:GetSecretValue" &&
      jsondecode(aws_iam_policy.policy[0].policy).Statement[0].Resource == "arn:aws:secretsmanager:us-east-1:123456789012:secret:identity-test/*" &&
      aws_iam_role_policy_attachment.policy_attachment[0].policy_arn == aws_iam_policy.policy[0].arn
    )
    error_message = "The YAML policy must be converted to an IAM JSON document, substituted, and attached to the role."
  }
}

run "json_policy_document" {
  command = plan
  module {
    source = "./IAM-Roles"
  }
  variables {
    iam_role = {
      key                = "json-policy"
      name               = "json-policy"
      assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
      policy = {
        name          = "json-policy"
        policy        = "tests/fixtures/service-account-policy.json"
        custom_policy = false
      }
    }
  }
  assert {
    condition = (
      jsondecode(aws_iam_policy.policy[0].policy).Statement[0].Action == "s3:GetObject" &&
      jsondecode(aws_iam_policy.policy[0].policy).Statement[0].Resource == "arn:aws:s3:::example-application-bucket/*"
    )
    error_message = "Existing JSON policy files must remain supported."
  }
}
