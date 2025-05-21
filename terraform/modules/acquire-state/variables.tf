variable "tf_remote_states" {
  description = "List of remote states to acquire"
  type = list(object({
    name            = string
    bucket_name     = string
    bucket_key      = string
    lock_table_name = string
  }))

}
