include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../"
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  common      = local.common_vars.locals.common
}

inputs = {
  common = local.common

  cognito = {
    name = "my-app-users"

    username_attributes        = ["email"]
    auto_verified_attributes   = ["email"]
    mfa_configuration          = "OPTIONAL"
    software_token_mfa_enabled = true

    password_policy = {
      minimum_length    = 12
      require_lowercase = true
      require_uppercase = true
      require_numbers   = true
      require_symbols   = true
    }

    clients = [
      {
        name                = "web-app"
        generate_secret     = false
        explicit_auth_flows = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
      }
    ]

    secret = {
      create           = true
      name             = "my-app-users/cognito"
      user_pool_id_key = "VITE_COGNITO_USER_POOL_ID"
      region_key       = "VITE_COGNITO_REGION"

      clients = {
        "web-app" = {
          client_id_key = "VITE_COGNITO_CLIENT_ID"
        }
      }
    }
  }
}
