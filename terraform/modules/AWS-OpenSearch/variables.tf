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

variable "opensearch" {
  description = "AWS OpenSearch domain configuration."
  type = object({
    domain_name    = string
    engine_version = optional(string, "OpenSearch_2.11")

    # Cluster configuration
    cluster_config = optional(object({
      instance_type            = optional(string, "r6g.large.search")
      instance_count           = optional(number, 2)
      dedicated_master_enabled = optional(bool, false)
      dedicated_master_type    = optional(string, null)
      dedicated_master_count   = optional(number, null)
      zone_awareness_enabled   = optional(bool, true)
      availability_zone_count  = optional(number, 2)
      warm_enabled             = optional(bool, false)
      warm_type                = optional(string, null)
      warm_count               = optional(number, null)
    }), {})

    # EBS options
    ebs_options = optional(object({
      ebs_enabled = optional(bool, true)
      volume_type = optional(string, "gp3")
      volume_size = optional(number, 100)
      iops        = optional(number, 3000)
      throughput  = optional(number, 125)
    }), {})

    # Encryption at rest
    encrypt_at_rest = optional(object({
      enabled    = optional(bool, true)
      kms_key_id = optional(string, null)
    }), {})

    # Node-to-node encryption
    node_to_node_encryption = optional(bool, true)

    # Domain endpoint options
    domain_endpoint_options = optional(object({
      enforce_https                   = optional(bool, true)
      tls_security_policy             = optional(string, "Policy-Min-TLS-1-2-2019-07")
      custom_endpoint_enabled         = optional(bool, false)
      custom_endpoint                 = optional(string, null)
      custom_endpoint_certificate_arn = optional(string, null)
    }), {})

    # VPC options (null = public domain)
    vpc_options = optional(object({
      subnet_ids         = list(string)
      security_group_ids = list(string)
    }), null)

    # Fine-grained access control
    advanced_security_options = optional(object({
      enabled                        = optional(bool, true)
      anonymous_auth_enabled         = optional(bool, false)
      internal_user_database_enabled = optional(bool, false)
      master_user_options = optional(object({
        master_user_arn      = optional(string, null)
        master_user_name     = optional(string, null)
        master_user_password = optional(string, null)
      }), null)
    }), null)

    # Access policies (JSON string)
    access_policies = optional(string, null)

    # Auto-tune
    auto_tune_desired_state = optional(string, null) # ENABLED or DISABLED

    # Advanced options
    advanced_options = optional(map(string), null)

    # Log publishing
    log_publishing = optional(object({
      index_slow_logs_enabled     = optional(bool, false)
      search_slow_logs_enabled    = optional(bool, false)
      es_application_logs_enabled = optional(bool, true)
      audit_logs_enabled          = optional(bool, false)
      log_retention_days          = optional(number, 14)
    }), {})

    tags = optional(map(string), {})
  })
}
