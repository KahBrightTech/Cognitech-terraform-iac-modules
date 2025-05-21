#--------------------------------------------------------------------
# Remote state backend configuration
#--------------------------------------------------------------------
output "remote_tfstates" {
  description = "Remote state backend configuration"
  value       = length(data.terraform_remote_state.states) > 0 ? data.terraform_remote_state.states : null
  sensitive   = true
}
