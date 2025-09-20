variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global           = bool
    tags             = map(string)
    account_name     = string
    region_prefix    = string
    account_name_abr = optional(string)
  })
}

variable "datasync" {
  description = "DataSync configuration with all location types and task settings"
  type = object({
    # Common Configuration
    location_type = string
    # S3 Location Configuration
    s3_location = optional(object({
      s3_bucket_arn          = string
      subdirectory           = optional(string)
      bucket_access_role_arn = string
      s3_storage_class       = optional(string)
    }))

    # EFS Location Configuration
    efs_location = optional(object({
      name                = string
      efs_file_system_arn = string
      access_point_arn    = optional(string)
      subdirectory        = optional(string)
      ec2_config = object({
        security_group_arns = list(string)
        subnet_arn          = string
      })
      in_transit_encryption = optional(string)
    }))

    # FSx for Windows File System Location Configuration
    fsx_windows_location = optional(object({
      fsx_filesystem_arn  = string
      subdirectory        = optional(string)
      user                = string
      domain              = optional(string)
      password            = string
      security_group_arns = list(string)
    }))

    # FSx for Lustre Location Configuration
    fsx_lustre_location = optional(object({
      fsx_filesystem_arn  = string
      subdirectory        = optional(string)
      security_group_arns = list(string)
    }))

    # FSx for NetApp ONTAP Location Configuration
    fsx_ontap_location = optional(object({
      subdirectory = optional(string)
      protocol = object({
        nfs = optional(object({
          mount_options = object({
            version = optional(string)
          })
        }))
        smb = optional(object({
          domain = optional(string)
          mount_options = object({
            version = optional(string)
          })
          password = string
          user     = string
        }))
      })
      security_group_arns         = list(string)
      storage_virtual_machine_arn = string
    }))

    # FSx for OpenZFS Location Configuration
    fsx_openzfs_location = optional(object({
      fsx_filesystem_arn = string
      subdirectory       = optional(string)
      protocol = object({
        nfs = object({
          mount_options = object({
            version = optional(string)
          })
        })
      })
      security_group_arns = list(string)
    }))

    # NFS Location Configuration
    nfs_location = optional(object({
      server_hostname = string
      subdirectory    = string
      on_prem_config = object({
        agent_arns = list(string)
      })
      mount_options = optional(object({
        version = optional(string)
      }))
    }))

    # SMB Location Configuration
    smb_location = optional(object({
      location_name   = string
      agent_arns      = list(string)
      domain          = optional(string)
      password        = string
      server_hostname = string
      subdirectory    = string
      user            = string
      mount_options = optional(object({
        version = optional(string)
      }))
    }))

    # HDFS Location Configuration
    hdfs_location = optional(object({
      location_name        = string
      cluster_type         = string
      agent_arns           = list(string)
      authentication_type  = optional(string)
      block_size           = optional(number)
      kerberos_keytab      = optional(string)
      kerberos_krb5_conf   = optional(string)
      kerberos_principal   = optional(string)
      kms_key_provider_uri = optional(string)
      namenode_configs = list(object({
        hostname = string
        port     = number
      }))
      qop_configuration = optional(object({
        data_transfer_protection = optional(string)
        rpc_protection           = optional(string)
      }))
      replication_factor = optional(number)
      simple_user        = optional(string)
      subdirectory       = string
    }))

    # Object Storage Location Configuration
    object_storage_location = optional(object({
      location_name      = string
      agent_arns         = list(string)
      bucket_name        = string
      server_hostname    = string
      subdirectory       = optional(string)
      access_key         = optional(string)
      secret_key         = optional(string)
      server_port        = optional(number)
      server_protocol    = optional(string)
      server_certificate = optional(string)
    }))

    # Azure Blob Storage Location Configuration
    azure_blob_location = optional(object({
      location_name       = string
      agent_arns          = list(string)
      container_url       = string
      subdirectory        = optional(string)
      authentication_type = string
      sas_configuration = optional(object({
        token = string
      }))
      blob_type   = optional(string)
      access_tier = optional(string)
    }))
  })
  default = null
}
