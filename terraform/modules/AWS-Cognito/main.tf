#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix    = "${var.common.account_name}-${var.common.region_prefix}"
  user_pool_name = "${local.name_prefix}-${var.cognito.name}"

  clients            = coalesce(var.cognito.clients, [])
  resource_servers   = coalesce(var.cognito.resource_servers, [])
  user_groups        = coalesce(var.cognito.user_groups, [])
  identity_providers = coalesce(var.cognito.identity_providers, [])
  schema_attributes  = coalesce(var.cognito.schema_attributes, [])

  clients_map            = { for c in local.clients : c.name => c }
  resource_servers_map   = { for rs in local.resource_servers : rs.identifier => rs }
  user_groups_map        = { for g in local.user_groups : g.name => g }
  identity_providers_map = { for idp in local.identity_providers : idp.provider_name => idp }
  lambda_triggers = var.cognito.lambda_config == null ? {} : {
    for k, v in {
      CreateAuthChallenge         = var.cognito.lambda_config.create_auth_challenge
      CustomMessage               = var.cognito.lambda_config.custom_message
      DefineAuthChallenge         = var.cognito.lambda_config.define_auth_challenge
      PostAuthentication          = var.cognito.lambda_config.post_authentication
      PostConfirmation            = var.cognito.lambda_config.post_confirmation
      PreAuthentication           = var.cognito.lambda_config.pre_authentication
      PreSignUp                   = var.cognito.lambda_config.pre_sign_up
      PreTokenGeneration          = var.cognito.lambda_config.pre_token_generation
      UserMigration               = var.cognito.lambda_config.user_migration
      VerifyAuthChallengeResponse = var.cognito.lambda_config.verify_auth_challenge_response
    } : k => v if v != null
  }

  identity_pool_enabled = try(var.cognito.identity_pool.create, false)

  #--------------------------------------------------------------------
  # Secrets Manager mirror (optional) - see var.cognito.secret
  #--------------------------------------------------------------------
  secret_cfg     = var.cognito.secret
  secret_enabled = try(local.secret_cfg.create, false)
  secret_name    = local.secret_enabled ? coalesce(try(local.secret_cfg.name, null), "${local.user_pool_name}/cognito") : null
  secret_primary_client_name = local.secret_enabled ? coalesce(
    try(local.secret_cfg.primary_client_name, null),
    try(local.clients[0].name, null)
  ) : null

  secret_payload = local.secret_enabled ? {
    for key, value in merge(
      {
        COGNITO_USER_POOL_ID       = aws_cognito_user_pool.this.id
        COGNITO_REGION             = data.aws_region.current.region
        COGNITO_USER_POOL_ARN      = aws_cognito_user_pool.this.arn
        COGNITO_USER_POOL_NAME     = aws_cognito_user_pool.this.name
        COGNITO_USER_POOL_ENDPOINT = aws_cognito_user_pool.this.endpoint
      },
      local.secret_primary_client_name != null ? {
        COGNITO_PRIMARY_CLIENT_NAME   = local.secret_primary_client_name
        COGNITO_PRIMARY_CLIENT_ID     = try(aws_cognito_user_pool_client.this[local.secret_primary_client_name].id, null)
        COGNITO_PRIMARY_CLIENT_SECRET = try(aws_cognito_user_pool_client.this[local.secret_primary_client_name].client_secret, null)
      } : {},
      try(aws_cognito_user_pool_domain.this[0].domain, null) != null ? {
        COGNITO_DOMAIN = aws_cognito_user_pool_domain.this[0].domain
      } : {},
      local.identity_pool_enabled ? {
        COGNITO_IDENTITY_POOL_ID = try(aws_cognito_identity_pool.this[0].id, null)
      } : {},
      try(local.secret_cfg.additional_values, {})
    ) : key => value if value != null
  } : {}
}

#--------------------------------------------------------------------
# Cognito User Pool
#--------------------------------------------------------------------
resource "aws_cognito_user_pool" "this" {
  name = local.user_pool_name

  deletion_protection      = var.cognito.deletion_protection
  alias_attributes         = var.cognito.alias_attributes
  username_attributes      = var.cognito.username_attributes
  auto_verified_attributes = var.cognito.auto_verified_attributes
  mfa_configuration        = var.cognito.mfa_configuration

  password_policy {
    minimum_length                   = var.cognito.password_policy.minimum_length
    require_lowercase                = var.cognito.password_policy.require_lowercase
    require_numbers                  = var.cognito.password_policy.require_numbers
    require_symbols                  = var.cognito.password_policy.require_symbols
    require_uppercase                = var.cognito.password_policy.require_uppercase
    temporary_password_validity_days = var.cognito.password_policy.temporary_password_validity_days
  }

  dynamic "username_configuration" {
    for_each = var.cognito.username_configuration != null ? [var.cognito.username_configuration] : []
    content {
      case_sensitive = username_configuration.value.case_sensitive
    }
  }

  dynamic "sms_configuration" {
    for_each = var.cognito.sms_configuration != null ? [var.cognito.sms_configuration] : []
    content {
      external_id    = sms_configuration.value.external_id
      sns_caller_arn = sms_configuration.value.sns_caller_arn
      sns_region     = sms_configuration.value.sns_region
    }
  }

  dynamic "software_token_mfa_configuration" {
    for_each = var.cognito.software_token_mfa_enabled ? [1] : []
    content {
      enabled = true
    }
  }

  dynamic "email_configuration" {
    for_each = var.cognito.email_configuration != null ? [var.cognito.email_configuration] : []
    content {
      email_sending_account  = email_configuration.value.email_sending_account
      from_email_address     = email_configuration.value.from_email_address
      reply_to_email_address = email_configuration.value.reply_to_email_address
      source_arn             = email_configuration.value.source_arn
      configuration_set      = email_configuration.value.configuration_set
    }
  }

  dynamic "admin_create_user_config" {
    for_each = var.cognito.admin_create_user_config != null ? [var.cognito.admin_create_user_config] : []
    content {
      allow_admin_create_user_only = admin_create_user_config.value.allow_admin_create_user_only

      dynamic "invite_message_template" {
        for_each = (
          admin_create_user_config.value.invite_email_subject != null ||
          admin_create_user_config.value.invite_email_message != null ||
          admin_create_user_config.value.invite_sms_message != null
        ) ? [admin_create_user_config.value] : []
        content {
          email_subject = invite_message_template.value.invite_email_subject
          email_message = invite_message_template.value.invite_email_message
          sms_message   = invite_message_template.value.invite_sms_message
        }
      }
    }
  }

  dynamic "device_configuration" {
    for_each = var.cognito.device_configuration != null ? [var.cognito.device_configuration] : []
    content {
      challenge_required_on_new_device      = device_configuration.value.challenge_required_on_new_device
      device_only_remembered_on_user_prompt = device_configuration.value.device_only_remembered_on_user_prompt
    }
  }

  dynamic "user_pool_add_ons" {
    for_each = var.cognito.advanced_security_mode != "OFF" ? [1] : []
    content {
      advanced_security_mode = var.cognito.advanced_security_mode
    }
  }

  dynamic "schema" {
    for_each = local.schema_attributes
    content {
      name                     = schema.value.name
      attribute_data_type      = schema.value.attribute_data_type
      developer_only_attribute = schema.value.developer_only_attribute
      mutable                  = schema.value.mutable
      required                 = schema.value.required

      dynamic "string_attribute_constraints" {
        for_each = schema.value.string_constraints != null ? [schema.value.string_constraints] : []
        content {
          min_length = string_attribute_constraints.value.min_length
          max_length = string_attribute_constraints.value.max_length
        }
      }

      dynamic "number_attribute_constraints" {
        for_each = schema.value.number_constraints != null ? [schema.value.number_constraints] : []
        content {
          min_value = number_attribute_constraints.value.min_value
          max_value = number_attribute_constraints.value.max_value
        }
      }
    }
  }

  dynamic "verification_message_template" {
    for_each = var.cognito.verification_message_template != null ? [var.cognito.verification_message_template] : []
    content {
      default_email_option  = verification_message_template.value.default_email_option
      email_message         = verification_message_template.value.email_message
      email_message_by_link = verification_message_template.value.email_message_by_link
      email_subject         = verification_message_template.value.email_subject
      email_subject_by_link = verification_message_template.value.email_subject_by_link
      sms_message           = verification_message_template.value.sms_message
    }
  }

  dynamic "lambda_config" {
    for_each = var.cognito.lambda_config != null ? [var.cognito.lambda_config] : []
    content {
      create_auth_challenge          = lambda_config.value.create_auth_challenge
      custom_message                 = lambda_config.value.custom_message
      define_auth_challenge          = lambda_config.value.define_auth_challenge
      post_authentication            = lambda_config.value.post_authentication
      post_confirmation              = lambda_config.value.post_confirmation
      pre_authentication             = lambda_config.value.pre_authentication
      pre_sign_up                    = lambda_config.value.pre_sign_up
      pre_token_generation           = lambda_config.value.pre_token_generation
      user_migration                 = lambda_config.value.user_migration
      verify_auth_challenge_response = lambda_config.value.verify_auth_challenge_response
      kms_key_id                     = lambda_config.value.kms_key_id
    }
  }

  tags = merge(var.common.tags, var.cognito.tags, {
    "Name" = local.user_pool_name
  })
}

#--------------------------------------------------------------------
# Grant Cognito permission to invoke any configured Lambda triggers
#--------------------------------------------------------------------
resource "aws_lambda_permission" "triggers" {
  for_each = var.cognito.create_lambda_permissions ? local.lambda_triggers : {}

  statement_id  = "AllowCognito${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.this.arn
}

#--------------------------------------------------------------------
# Resource Servers (custom OAuth scopes)
#--------------------------------------------------------------------
resource "aws_cognito_resource_server" "this" {
  for_each = local.resource_servers_map

  identifier   = each.value.identifier
  name         = each.value.name
  user_pool_id = aws_cognito_user_pool.this.id

  dynamic "scope" {
    for_each = each.value.scopes
    content {
      scope_name        = scope.value.scope_name
      scope_description = scope.value.scope_description
    }
  }
}

#--------------------------------------------------------------------
# Identity Providers (federation)
#--------------------------------------------------------------------
resource "aws_cognito_identity_provider" "this" {
  for_each = local.identity_providers_map

  user_pool_id      = aws_cognito_user_pool.this.id
  provider_name     = each.value.provider_name
  provider_type     = each.value.provider_type
  provider_details  = each.value.provider_details
  attribute_mapping = each.value.attribute_mapping
  idp_identifiers   = each.value.idp_identifiers
}

#--------------------------------------------------------------------
# User Pool App Clients
#--------------------------------------------------------------------
resource "aws_cognito_user_pool_client" "this" {
  for_each = local.clients_map

  name         = each.value.name
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret     = each.value.generate_secret
  explicit_auth_flows = each.value.explicit_auth_flows

  allowed_oauth_flows                  = each.value.allowed_oauth_flows
  allowed_oauth_flows_user_pool_client = each.value.allowed_oauth_flows_user_pool_client
  allowed_oauth_scopes                 = each.value.allowed_oauth_scopes

  callback_urls        = each.value.callback_urls
  logout_urls          = each.value.logout_urls
  default_redirect_uri = each.value.default_redirect_uri

  supported_identity_providers = each.value.supported_identity_providers

  prevent_user_existence_errors = each.value.prevent_user_existence_errors

  refresh_token_validity = each.value.refresh_token_validity
  access_token_validity  = each.value.access_token_validity
  id_token_validity      = each.value.id_token_validity

  dynamic "token_validity_units" {
    for_each = each.value.token_validity_units != null ? [each.value.token_validity_units] : []
    content {
      access_token  = token_validity_units.value.access_token
      id_token      = token_validity_units.value.id_token
      refresh_token = token_validity_units.value.refresh_token
    }
  }

  read_attributes  = each.value.read_attributes
  write_attributes = each.value.write_attributes

  enable_token_revocation                       = each.value.enable_token_revocation
  enable_propagate_additional_user_context_data = each.value.enable_propagate_additional_user_context_data

  depends_on = [aws_cognito_resource_server.this, aws_cognito_identity_provider.this]
}

#--------------------------------------------------------------------
# Hosted UI Domain
#--------------------------------------------------------------------
resource "aws_cognito_user_pool_domain" "this" {
  count = var.cognito.domain != null ? 1 : 0

  domain          = var.cognito.domain.domain_name
  certificate_arn = var.cognito.domain.certificate_arn
  user_pool_id    = aws_cognito_user_pool.this.id
}

#--------------------------------------------------------------------
# User Groups
#--------------------------------------------------------------------
resource "aws_cognito_user_group" "this" {
  for_each = local.user_groups_map

  name         = each.value.name
  user_pool_id = aws_cognito_user_pool.this.id
  description  = each.value.description
  precedence   = each.value.precedence
  role_arn     = each.value.role_arn
}

#--------------------------------------------------------------------
# Identity Pool (optional - federated AWS credential vending)
#--------------------------------------------------------------------
resource "aws_cognito_identity_pool" "this" {
  count = local.identity_pool_enabled ? 1 : 0

  identity_pool_name               = coalesce(try(var.cognito.identity_pool.name, null), "${local.user_pool_name}-identity-pool")
  allow_unauthenticated_identities = try(var.cognito.identity_pool.allow_unauthenticated_identities, false)
  allow_classic_flow               = try(var.cognito.identity_pool.allow_classic_flow, false)

  dynamic "cognito_identity_providers" {
    for_each = concat(
      [for name, c in aws_cognito_user_pool_client.this : {
        client_id               = c.id
        provider_name           = aws_cognito_user_pool.this.endpoint
        server_side_token_check = try(var.cognito.identity_pool.server_side_token_check, false)
      }],
      try(var.cognito.identity_pool.additional_cognito_providers, [])
    )
    content {
      client_id               = cognito_identity_providers.value.client_id
      provider_name           = cognito_identity_providers.value.provider_name
      server_side_token_check = cognito_identity_providers.value.server_side_token_check
    }
  }

  tags = merge(var.common.tags, var.cognito.tags, {
    "Name" = coalesce(try(var.cognito.identity_pool.name, null), "${local.user_pool_name}-identity-pool")
  })
}

#--------------------------------------------------------------------
# Secrets Manager 
#--------------------------------------------------------------------
resource "aws_secretsmanager_secret" "this" {
  count = local.secret_enabled ? 1 : 0

  name_prefix             = local.secret_name
  description             = coalesce(try(var.cognito.secret.description, null), "Cognito user pool config for ${local.user_pool_name}")
  kms_key_id              = try(var.cognito.secret.kms_key_id, null)
  recovery_window_in_days = try(var.cognito.secret.recovery_window_in_days, 30)
  tags = merge(var.common.tags, var.cognito.tags, {
    "Name" = local.secret_name
  })

  depends_on = [
    aws_cognito_user_pool.this,
    aws_cognito_user_pool_client.this,
    aws_cognito_resource_server.this,
    aws_cognito_identity_provider.this,
    aws_cognito_user_pool_domain.this,
    aws_cognito_user_group.this,
    aws_lambda_permission.triggers,
    aws_cognito_identity_pool.this,
    aws_cognito_identity_pool_roles_attachment.this,
  ]
}

resource "aws_secretsmanager_secret_version" "this" {
  count = local.secret_enabled ? 1 : 0

  secret_id     = aws_secretsmanager_secret.this[0].id
  secret_string = jsonencode(local.secret_payload)

  depends_on = [
    aws_cognito_user_pool.this,
    aws_cognito_user_pool_client.this,
    aws_cognito_resource_server.this,
    aws_cognito_identity_provider.this,
    aws_cognito_user_pool_domain.this,
    aws_cognito_user_group.this,
    aws_lambda_permission.triggers,
    aws_cognito_identity_pool.this,
    aws_cognito_identity_pool_roles_attachment.this,
  ]
}

resource "aws_cognito_identity_pool_roles_attachment" "this" {
  count = local.identity_pool_enabled && (
    try(var.cognito.identity_pool.authenticated_role_arn, null) != null ||
    try(var.cognito.identity_pool.unauthenticated_role_arn, null) != null
  ) ? 1 : 0

  identity_pool_id = aws_cognito_identity_pool.this[0].id

  roles = merge(
    try(var.cognito.identity_pool.authenticated_role_arn, null) != null ? { "authenticated" = var.cognito.identity_pool.authenticated_role_arn } : {},
    try(var.cognito.identity_pool.unauthenticated_role_arn, null) != null ? { "unauthenticated" = var.cognito.identity_pool.unauthenticated_role_arn } : {}
  )
}
