variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global           = bool
    tags             = map(string)
    account_name     = string
    region_prefix    = string
    account_name_abr = optional(string, "")
  })
}

variable "cognito" {
  description = "AWS Cognito user pool, clients, domain, and identity pool configuration."
  type = object({
    name = string # Base name for the user pool (will be prefixed with account_name-region_prefix)

    deletion_protection        = optional(string, "INACTIVE") # ACTIVE or INACTIVE
    alias_attributes           = optional(list(string), null) # e.g. ["email", "phone_number", "preferred_username"] - mutually exclusive with username_attributes
    username_attributes        = optional(list(string), null) # e.g. ["email"] or ["phone_number"] - mutually exclusive with alias_attributes
    auto_verified_attributes   = optional(list(string), ["email"])
    mfa_configuration          = optional(string, "OFF") # OFF, ON, OPTIONAL
    software_token_mfa_enabled = optional(bool, false)

    username_configuration = optional(object({
      case_sensitive = optional(bool, false)
    }), null)

    #--------------------------------------------------------------------
    # Password Policy
    #--------------------------------------------------------------------
    password_policy = optional(object({
      minimum_length                   = optional(number, 8)
      require_lowercase                = optional(bool, true)
      require_numbers                  = optional(bool, true)
      require_symbols                  = optional(bool, true)
      require_uppercase                = optional(bool, true)
      temporary_password_validity_days = optional(number, 7)
    }), {})

    #--------------------------------------------------------------------
    # SMS / Email Configuration
    #--------------------------------------------------------------------
    sms_configuration = optional(object({
      external_id    = string
      sns_caller_arn = string
      sns_region     = optional(string, null)
    }), null)

    email_configuration = optional(object({
      email_sending_account  = optional(string, "COGNITO_DEFAULT") # COGNITO_DEFAULT or DEVELOPER
      from_email_address     = optional(string, null)
      reply_to_email_address = optional(string, null)
      source_arn             = optional(string, null)
      configuration_set      = optional(string, null)
    }), null)

    #--------------------------------------------------------------------
    # Admin Create User / Device / Advanced Security
    #--------------------------------------------------------------------
    admin_create_user_config = optional(object({
      allow_admin_create_user_only = optional(bool, false)
      invite_email_subject         = optional(string, null)
      invite_email_message         = optional(string, null)
      invite_sms_message           = optional(string, null)
    }), null)

    device_configuration = optional(object({
      challenge_required_on_new_device      = optional(bool, false)
      device_only_remembered_on_user_prompt = optional(bool, false)
    }), null)

    advanced_security_mode = optional(string, "OFF") # OFF, AUDIT, ENFORCED

    #--------------------------------------------------------------------
    # Schema (custom attributes)
    #--------------------------------------------------------------------
    schema_attributes = optional(list(object({
      name                     = string
      attribute_data_type      = string # String, Number, DateTime, Boolean
      developer_only_attribute = optional(bool, false)
      mutable                  = optional(bool, true)
      required                 = optional(bool, false)
      string_constraints = optional(object({
        min_length = optional(string, null)
        max_length = optional(string, null)
      }), null)
      number_constraints = optional(object({
        min_value = optional(string, null)
        max_value = optional(string, null)
      }), null)
    })), [])

    #--------------------------------------------------------------------
    # Verification Messages
    #--------------------------------------------------------------------
    verification_message_template = optional(object({
      default_email_option  = optional(string, "CONFIRM_WITH_CODE") # CONFIRM_WITH_CODE or CONFIRM_WITH_LINK
      email_message         = optional(string, null)
      email_message_by_link = optional(string, null)
      email_subject         = optional(string, null)
      email_subject_by_link = optional(string, null)
      sms_message           = optional(string, null)
    }), null)

    #--------------------------------------------------------------------
    # Lambda Triggers
    #--------------------------------------------------------------------
    lambda_config = optional(object({
      create_auth_challenge          = optional(string, null)
      custom_message                 = optional(string, null)
      define_auth_challenge          = optional(string, null)
      post_authentication            = optional(string, null)
      post_confirmation              = optional(string, null)
      pre_authentication             = optional(string, null)
      pre_sign_up                    = optional(string, null)
      pre_token_generation           = optional(string, null)
      user_migration                 = optional(string, null)
      verify_auth_challenge_response = optional(string, null)
      kms_key_id                     = optional(string, null)
    }), null)

    # Automatically grant Cognito permission to invoke every Lambda referenced in lambda_config
    create_lambda_permissions = optional(bool, true)

    #--------------------------------------------------------------------
    # Hosted UI Domain
    #--------------------------------------------------------------------
    domain = optional(object({
      domain_name     = string                 # Cognito domain prefix, or fully qualified domain name for custom domain
      certificate_arn = optional(string, null) # Required (ACM cert in us-east-1) when using a custom domain
    }), null)

    #--------------------------------------------------------------------
    # App Clients
    #--------------------------------------------------------------------
    clients = optional(list(object({
      name                                 = string
      generate_secret                      = optional(bool, false)
      explicit_auth_flows                  = optional(list(string), ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"])
      allowed_oauth_flows                  = optional(list(string), [])
      allowed_oauth_flows_user_pool_client = optional(bool, false)
      allowed_oauth_scopes                 = optional(list(string), [])
      callback_urls                        = optional(list(string), [])
      logout_urls                          = optional(list(string), [])
      supported_identity_providers         = optional(list(string), ["COGNITO"])
      prevent_user_existence_errors        = optional(string, "ENABLED")
      refresh_token_validity               = optional(number, 30)
      access_token_validity                = optional(number, 60)
      id_token_validity                    = optional(number, 60)
      token_validity_units = optional(object({
        access_token  = optional(string, "minutes")
        id_token      = optional(string, "minutes")
        refresh_token = optional(string, "days")
      }), {})
      read_attributes                               = optional(list(string), null)
      write_attributes                              = optional(list(string), null)
      enable_token_revocation                       = optional(bool, true)
      enable_propagate_additional_user_context_data = optional(bool, false)
      default_redirect_uri                          = optional(string, null)
    })), [])

    #--------------------------------------------------------------------
    # Resource Servers (custom OAuth scopes)
    #--------------------------------------------------------------------
    resource_servers = optional(list(object({
      identifier = string
      name       = string
      scopes = list(object({
        scope_name        = string
        scope_description = string
      }))
    })), [])

    #--------------------------------------------------------------------
    # User Groups
    #--------------------------------------------------------------------
    user_groups = optional(list(object({
      name        = string
      description = optional(string, null)
      precedence  = optional(number, null)
      role_arn    = optional(string, null)
    })), [])

    #--------------------------------------------------------------------
    # Identity Providers (federation - Google, Facebook, SAML, OIDC, etc.)
    #--------------------------------------------------------------------
    identity_providers = optional(list(object({
      provider_name     = string
      provider_type     = string # SAML, Google, Facebook, LoginWithAmazon, SignInWithApple, OIDC
      provider_details  = map(string)
      attribute_mapping = optional(map(string), {})
      idp_identifiers   = optional(list(string), [])
    })), [])

    #--------------------------------------------------------------------
    # Identity Pool (federated identities / AWS credential vending)
    #--------------------------------------------------------------------
    identity_pool = optional(object({
      create                           = optional(bool, false)
      name                             = optional(string, null)
      allow_unauthenticated_identities = optional(bool, false)
      allow_classic_flow               = optional(bool, false)
      authenticated_role_arn           = optional(string, null)
      unauthenticated_role_arn         = optional(string, null)
      server_side_token_check          = optional(bool, false)
      # Additional user pool clients to trust in the identity pool beyond the ones this module creates
      additional_cognito_providers = optional(list(object({
        client_id               = string
        provider_name           = string
        server_side_token_check = optional(bool, false)
      })), [])
    }), null)

    tags = optional(map(string), {})
  })
}
