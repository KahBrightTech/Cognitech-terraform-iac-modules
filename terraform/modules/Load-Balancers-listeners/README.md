# Load Balancer Listeners Module

This Terraform module creates an AWS Application Load Balancer (ALB) listener with dynamic default actions. The module supports two types of default actions:

1. **Fixed Response** - Returns a static HTTP response
2. **Forward** - Forwards requests to a target group

## Features

- Dynamic default action configuration
- Support for SSL/TLS listeners with certificate management
- Optional target group forwarding with stickiness configuration
- Customizable fixed response messages

## Usage

### Example 1: Fixed Response Listener

```hcl
module "alb_listener_fixed" {
  source = "./modules/Load-Balancers-listeners"
  
  common = var.common
  
  listener = {
    load_balancer_arn = aws_lb.main.arn
    port              = 80
    protocol          = "HTTP"
    
    fixed_response = {
      content_type = "text/html"
      message_body = "<h1>503 Service Unavailable</h1><p>Maintenance in progress.</p>"
      status_code  = "503"
    }
  }
}
```

### Example 2: Forward to Target Group

```hcl
module "alb_listener_forward" {
  source = "./modules/Load-Balancers-listeners"
  
  common = var.common
  
  listener = {
    load_balancer_arn = aws_lb.main.arn
    port              = 443
    protocol          = "HTTPS"
    ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
    certificate_arn   = aws_acm_certificate.main.arn
    
    forward = {
      target_group_arn = aws_lb_target_group.main.arn
      stickiness = {
        enabled  = true
        type     = "lb_cookie"
        duration = 86400  # 24 hours
      }
    }
  }
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| common | Common variables used by all resources | `object` | n/a | yes |
| listener | Load Balancer listener configuration | `object` | n/a | yes |

### Listener Object

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| load_balancer_arn | ARN of the load balancer | `string` | n/a | yes |
| port | Port number for the listener | `number` | n/a | yes |
| protocol | Protocol for the listener (HTTP, HTTPS) | `string` | n/a | yes |
| ssl_policy | SSL security policy for HTTPS listeners | `string` | `null` | no |
| certificate_arn | ARN of the SSL certificate for HTTPS listeners | `string` | `null` | no |
| fixed_response | Fixed response configuration (mutually exclusive with forward) | `object` | `null` | no |
| forward | Forward action configuration (mutually exclusive with fixed_response) | `object` | `null` | no |

### Fixed Response Object

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| content_type | Content type of the response | `string` | `"text/plain"` | no |
| message_body | Body of the response | `string` | `"Oops! The page you are looking for does not exist."` | no |
| status_code | HTTP status code | `string` | `"200"` | no |

### Forward Object

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| target_group_arn | ARN of the target group | `string` | n/a | yes |
| stickiness | Session stickiness configuration | `object` | `null` | no |

### Stickiness Object

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enabled | Whether to enable stickiness | `bool` | n/a | yes |
| type | Type of stickiness (lb_cookie) | `string` | n/a | yes |
| duration | Duration of stickiness in seconds | `number` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| listener_arn | The ARN of the Load Balancer listener |
| listener_id | The ID of the Load Balancer listener |
| listener_port | The port of the Load Balancer listener |
| listener_protocol | The protocol of the Load Balancer listener |
| listener_ssl_policy | The SSL policy of the Load Balancer listener |
| listener_certificate_arn | The ARN of the certificate associated with the Load Balancer listener |
| listener_default_action | The default action of the Load Balancer listener |

## Notes

- Either `fixed_response` or `forward` must be specified, but not both
- SSL/TLS listeners (HTTPS) require a valid `certificate_arn`
- The `ssl_policy` is only applicable for HTTPS listeners
- Session stickiness is only available when using the forward action
