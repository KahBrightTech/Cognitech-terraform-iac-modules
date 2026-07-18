# AWS Cognito Module

This Terraform module creates an AWS Cognito User Pool along with its supporting resources: app clients, a hosted UI domain, custom resource servers (OAuth scopes), user groups, identity providers (federation), Lambda triggers (with invoke permissions), and an optional Identity Pool for vending temporary AWS credentials.

## Features

- Creates a Cognito User Pool with configurable password policy, MFA, verification, schema (custom attributes), and Lambda triggers
- Automatically grants Cognito `lambda:InvokeFunction` permission for every configured Lambda trigger
- Supports one or more app clients, each with their own OAuth/token settings
- Optional Cognito-managed or custom hosted UI domain
- Optional custom resource servers for defining custom OAuth scopes
- Optional user groups
- Optional identity providers for federation (Google, Facebook, Login with Amazon, Sign in with Apple, SAML, OIDC)
- Optional Identity Pool with IAM role attachment for authenticated/unauthenticated access

## Usage

```hcl
module "cognito" {
  source = "./modules/AWS-Cognito"

  common = {
    global        = false
    tags = {
      Environment = "production"
      Project     = "my-app"
    }
    account_name  = "myaccount"
    region_prefix = "us-east-1"
  }

  cognito = {
    name = "my-app-users"

    auto_verified_attributes = ["email"]
    username_attributes      = ["email"]
    mfa_configuration         = "OPTIONAL"
    software_token_mfa_enabled = true

    password_policy = {
      minimum_length     = 12
      require_symbols    = true
      require_numbers    = true
      require_lowercase  = true
      require_uppercase  = true
    }

    domain = {
      domain_name = "myaccount-my-app"
    }

    clients = [
      {
        name                                  = "web-app"
        generate_secret                       = false
        allowed_oauth_flows                   = ["code"]
        allowed_oauth_flows_user_pool_client   = true
        allowed_oauth_scopes                  = ["openid", "email", "profile"]
        callback_urls                         = ["https://app.example.com/callback"]
        logout_urls                           = ["https://app.example.com/logout"]
        supported_identity_providers          = ["COGNITO"]
      },
      {
        name             = "backend-service"
        generate_secret  = true
        explicit_auth_flows = ["ALLOW_ADMIN_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
      }
    ]

    resource_servers = [
      {
        identifier = "api"
        name       = "My App API"
        scopes = [
          { scope_name = "read", scope_description = "Read access" },
          { scope_name = "write", scope_description = "Write access" }
        ]
      }
    ]

    user_groups = [
      { name = "admins", description = "Administrators", precedence = 1 },
      { name = "users", description = "Standard users", precedence = 10 }
    ]

    lambda_config = {
      pre_sign_up          = "arn:aws:lambda:us-east-1:123456789012:function:pre-signup"
      post_confirmation    = "arn:aws:lambda:us-east-1:123456789012:function:post-confirmation"
    }

    identity_pool = {
      create                            = true
      allow_unauthenticated_identities  = false
      authenticated_role_arn            = "arn:aws:iam::123456789012:role/cognito-authenticated-role"
    }
  }
}
```

## Managing User Logins (e.g. a Patient/Provider Healthcare App)

If the goal is simply "let users sign up and log in to my app," the piece you need is the **User Pool** (`cognito.clients` against the pool this module creates) — not the Identity Pool.

- **User Pool** — this is Cognito's actual identity store: it handles sign-up, sign-in, password resets, MFA, email/SMS verification, and issues the JWTs (ID/access/refresh tokens) your app or backend validates on every request. This is "managing user logins."
- **Identity Pool** (the `cognito.identity_pool` block) — a separate, optional add-on that exchanges a login for *temporary AWS credentials* so a client can call AWS services (S3, DynamoDB, etc.) directly. Skip it entirely (leave `identity_pool` unset) unless your app talks to AWS directly from the browser/mobile device without going through your own backend. Most apps, including a typical doctor/patient app with its own API, don't need it.

So for a login-only setup: configure `cognito.clients` with one client per app surface (e.g. the patient-facing web app, a provider portal, a backend service) and don't set `identity_pool`.

### Recommended settings for a healthcare app

Because this app likely touches patient health data, it's worth being deliberate about a few settings beyond the defaults:

- `username_attributes = ["email"]` and `auto_verified_attributes = ["email"]` so people log in and verify with email (swap/add `phone_number` if you want SMS-based accounts too).
- A strong `password_policy` (12+ characters, all complexity flags on).
- `mfa_configuration = "ON"` (or `"OPTIONAL"` at minimum) with `software_token_mfa_enabled = true` for authenticator-app TOTP. Add `sms_configuration` if you also want SMS as a factor.
- `advanced_security_mode = "ENFORCED"` — enables Cognito's compromised-credential checks and risk-based adaptive authentication. This has additional AWS cost, but is a reasonable default for anything handling PHI.
- `user_groups` to separate roles (e.g. `doctors`, `patients`, `staff`). The group name shows up in the `cognito:groups` claim of the ID token, so your backend API can authorize requests off of it without a separate roles table.
- `admin_create_user_config.allow_admin_create_user_only = true` if provider/staff accounts should be created by an admin rather than self-registered; leave it `false` (default) if patients should be able to sign themselves up.
- `lambda_config.pre_token_generation` if you need to inject custom claims (e.g. `clinic_id`) into the token at login time.

```hcl
cognito = {
  name = "doctor-app-users"

  username_attributes       = ["email"]
  auto_verified_attributes  = ["email"]
  mfa_configuration          = "ON"
  software_token_mfa_enabled = true
  advanced_security_mode     = "ENFORCED"

  password_policy = {
    minimum_length    = 12
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true
  }

  admin_create_user_config = {
    allow_admin_create_user_only = true # staff/providers are onboarded by an admin
  }

  clients = [
    {
      name                 = "patient-portal"
      generate_secret      = false
      explicit_auth_flows  = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
    },
    {
      name                 = "provider-portal"
      generate_secret      = false
      explicit_auth_flows  = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
    }
  ]

  user_groups = [
    { name = "doctors", description = "Clinicians", precedence = 1 },
    { name = "staff", description = "Front-desk / admin staff", precedence = 5 },
    { name = "patients", description = "Patient accounts", precedence = 10 }
  ]

  # identity_pool intentionally omitted — not needed for login-only use cases
}
```

**HIPAA note:** Cognito is on AWS's list of HIPAA-eligible services, but eligibility isn't the same as compliance. If this app will handle PHI, you need a signed AWS Business Associate Addendum (BAA) on the account, should avoid putting PHI directly into Cognito attributes (which end up in JWT claims), and should pair this with CloudTrail logging and your org's usual HIPAA controls. Confirm the specifics with your compliance/legal team rather than relying on this module alone.

## Federated Identity Provider Example

```hcl
identity_providers = [
  {
    provider_name = "Google"
    provider_type = "Google"
    provider_details = {
      client_id        = "xxxxxxx.apps.googleusercontent.com"
      client_secret     = "xxxxxxxxxxxxxxxx"
      authorize_scopes  = "email openid profile"
    }
    attribute_mapping = {
      email    = "email"
      username = "sub"
    }
  }
]
```

## Inputs

| Name    | Description                                                         | Type   | Default | Required |
| ------- | ------------------------------------------------------------------- | ------ | ------- | -------- |
| common  | Common variables used by all resources                              | object | n/a     | yes      |
| cognito | Cognito user pool, clients, domain, and identity pool configuration | object | n/a     | yes      |

### Cognito Object (key fields)

| Name                          | Description                                                                       | Type         | Default          | Required |
| ----------------------------- | --------------------------------------------------------------------------------- | ------------ | ---------------- | -------- |
| name                          | Base name for the user pool (prefixed with`account_name-region_prefix`)         | string       | n/a              | yes      |
| deletion_protection           | `ACTIVE` or `INACTIVE`                                                        | string       | "INACTIVE"       | no       |
| alias_attributes              | Alias attributes (mutually exclusive with`username_attributes`)                 | list(string) | null             | no       |
| username_attributes           | Attributes usable as the username (mutually exclusive with`alias_attributes`)   | list(string) | null             | no       |
| auto_verified_attributes      | Attributes to auto-verify                                                         | list(string) | ["email"]        | no       |
| mfa_configuration             | `OFF`, `ON`, or `OPTIONAL`                                                  | string       | "OFF"            | no       |
| password_policy               | Password complexity requirements                                                  | object       | see variables.tf | no       |
| sms_configuration             | SNS role/external ID for SMS MFA                                                  | object       | null             | no       |
| email_configuration           | Email sending configuration                                                       | object       | null             | no       |
| admin_create_user_config      | Admin-only signup and invite message settings                                     | object       | null             | no       |
| device_configuration          | Remembered device settings                                                        | object       | null             | no       |
| advanced_security_mode        | `OFF`, `AUDIT`, or `ENFORCED`                                               | string       | "OFF"            | no       |
| schema_attributes             | Custom user pool attributes                                                       | list(object) | []               | no       |
| verification_message_template | Verification email/SMS templates                                                  | object       | null             | no       |
| lambda_config                 | Lambda trigger ARNs (create_auth_challenge, pre_sign_up, post_confirmation, etc.) | object       | null             | no       |
| create_lambda_permissions     | Automatically create`aws_lambda_permission` for each configured trigger         | bool         | true             | no       |
| domain                        | Hosted UI domain (Cognito-managed or custom with`certificate_arn`)              | object       | null             | no       |
| clients                       | List of app clients                                                               | list(object) | []               | no       |
| resource_servers              | List of custom OAuth resource servers/scopes                                      | list(object) | []               | no       |
| user_groups                   | List of user pool groups                                                          | list(object) | []               | no       |
| identity_providers            | List of federated identity providers                                              | list(object) | []               | no       |
| identity_pool                 | Optional Identity Pool configuration                                              | object       | null             | no       |
| tags                          | Additional tags merged with`common.tags`                                        | map(string)  | {}               | no       |

See `variables.tf` for the full nested schema and per-field defaults.

## Outputs

| Name                                     | Description                                            |
| ---------------------------------------- | ------------------------------------------------------ |
| user_pool_id                             | ID of the Cognito user pool                            |
| user_pool_arn                            | ARN of the Cognito user pool                           |
| user_pool_name                           | Name of the Cognito user pool                          |
| user_pool_endpoint                       | Endpoint of the Cognito user pool                      |
| user_pool_domain                         | Hosted UI domain, if created                           |
| user_pool_domain_cloudfront_distribution | CloudFront distribution ARN for the domain, if created |
| clients                                  | Map of client name to`{ id, secret }` (sensitive)    |
| resource_servers                         | Map of resource server identifier to ID                |
| user_groups                              | Map of group name to ID                                |
| identity_providers                       | Map of identity provider name to provider name         |
| identity_pool_id                         | ID of the Identity Pool, if created                    |
| identity_pool_arn                        | ARN of the Identity Pool, if created                   |

## Requirements

| Name      | Version   |
| --------- | --------- |
| terraform | >= 1.5.5  |
| aws       | >= 4.37.0 |

## Providers

| Name | Version   |
| ---- | --------- |
| aws  | >= 4.37.0 |

## Notes

- `alias_attributes` and `username_attributes` cannot both be set — choose one strategy.
- When `mfa_configuration` is `ON` or `OPTIONAL`, configure `sms_configuration` and/or set `software_token_mfa_enabled = true` so users have an MFA method available.
- A custom hosted UI domain requires an ACM certificate issued in `us-east-1`, regardless of the user pool's region.
- `clients[].client_secret` and the `clients` output are marked sensitive; reference them via `terraform output -json clients` or store consumers' secrets in Secrets Manager if needed elsewhere.
