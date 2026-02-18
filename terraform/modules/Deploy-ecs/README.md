# Deploy-ECS Terraform Module

This module provisions a complete AWS ECS (Elastic Container Service) infrastructure with support for both Fargate and EC2 launch types, including autoscaling, load balancing, and comprehensive monitoring capabilities.

## Table of Contents

- [Overview](#overview)
- [Architecture Components](#architecture-components)
- [Usage](#usage)
- [Resource Explanations](#resource-explanations)
- [IAM Roles Explained](#iam-roles-explained)
- [Capacity Providers](#capacity-providers)
- [Fargate vs EC2 Launch Types](#fargate-vs-ec2-launch-types)
- [Examples](#examples)

## Overview

This module creates a production-ready ECS environment that can:
- Run containerized applications on AWS Fargate (serverless) or EC2 instances
- Automatically scale infrastructure based on demand
- Integrate with Application/Network Load Balancers
- Enable secure debugging with ECS Exec
- Provide comprehensive monitoring with Container Insights
- Support both Linux and Windows containers

## Architecture Components

### Core ECS Resources

1. **ECS Cluster** - The logical grouping of services and tasks
2. **Task Definition** - Blueprint defining how to run your containers
3. **ECS Service** - Maintains desired number of tasks and handles scheduling
4. **Capacity Providers** - Manages compute capacity (Fargate or EC2)

### EC2 Infrastructure (Optional)

5. **Launch Template** - EC2 instance configuration
6. **Auto Scaling Group** - Pool of EC2 instances
7. **ECS Capacity Provider** - Links ASG to ECS with managed scaling
8. **Scaling Policies** - CloudWatch alarm-based scaling rules

## Usage

```hcl
module "ecs_cluster" {
  source = "./modules/Deploy-ecs"
  
  ecs = {
    common = {
      account_name     = "mycompany"
      region_prefix    = "us-east-1"
      account_name_abr = "mc"
      tags = {
        Environment = "production"
        ManagedBy   = "terraform"
      }
    }
    
    cluster_name               = "app-cluster"
    container_insights_enabled = true
    
    task_definition = {
      family                   = "my-app"
      task_role_arn            = "arn:aws:iam::123456789012:role/my-app-task-role"
      execution_role_arn       = "arn:aws:iam::123456789012:role/my-app-execution-role"
      network_mode             = "awsvpc"
      requires_compatibilities = ["FARGATE"]
      cpu                      = "256"
      memory                   = "512"
      container_definitions    = jsonencode([...])
    }
    
    service = {
      name                               = "my-service"
      desired_count                      = 2
      launch_type                        = "FARGATE"
      deployment_maximum_percent         = 200
      deployment_minimum_healthy_percent = 100
      
      network_configuration = {
        subnets          = ["subnet-abc123", "subnet-def456"]
        security_groups  = ["sg-xyz789"]
        assign_public_ip = false
      }
    }
  }
}
```

## Container Definitions

You can define container configurations in two ways:

### Option 1: Inline JSON (using jsonencode)

```hcl
task_definition = {
  family                = "my-app"
  # ... other settings ...
  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "nginx:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}
```

### Option 2: External JSON File (Recommended for complex configurations)

**Step 1:** Create a JSON file (e.g., `container-definitions.json`):

```json
[
  {
    "name": "nginx",
    "image": "nginx:latest",
    "cpu": 256,
    "memory": 512,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "protocol": "tcp"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/my-app",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "nginx"
      }
    }
  }
]
```

**Step 2:** Reference the file in your Terraform:

```hcl
task_definition = {
  family                     = "my-app"
  # ... other settings ...
  container_definitions_file = "${path.module}/container-definitions.json"
}
```

**Benefits of using a separate file:**
- Cleaner Terraform code
- Easier to edit and validate JSON
- Better for complex multi-container task definitions
- Can use JSON linting tools
- Easier to share configurations across environments

**Note:** You must specify either `container_definitions` (inline string) OR `container_definitions_file` (file path), not both. If both are provided, the file takes precedence.

See [examples/container-definitions.json](examples/container-definitions.json) for a complete example with health checks, secrets, and volume mounts.

## Resource Explanations

### ECS Cluster

The ECS cluster is the foundational resource that serves as a logical grouping for your services, tasks, and container instances.

**Key Features:**
- **Container Insights**: Collects CloudWatch metrics for CPU, memory, disk, and network usage
- **Execute Command Configuration**: Enables secure shell access to running containers for debugging

**Container Insights Behavior:**
- When enabled (`container_insights_enabled = true`), creates CloudWatch dashboards and metrics
- Incurs additional CloudWatch charges for metrics and logs
- Provides task-level and service-level performance monitoring

**ECS Exec (Execute Command):**
- Allows running commands inside containers without SSH access
- Sessions can be encrypted with KMS
- Logs can be stored in CloudWatch Logs or S3 for audit trails
- Example usage: `aws ecs execute-command --cluster my-cluster --task task-id --command "/bin/bash"`

### ECS Cluster Capacity Providers

Associates capacity providers with your cluster and defines the default distribution strategy.

**Purpose:**
- Links compute providers (Fargate, Fargate Spot, or custom EC2) to the cluster
- Does NOT create capacity providers, only associates existing ones
- Sets default strategy for task placement when not specified at service level

**Capacity Provider Strategy Parameters:**
- **capacity_provider**: Name of the provider (e.g., "FARGATE", "FARGATE_SPOT", or custom name)
- **weight**: Relative distribution of tasks (higher = more tasks)
- **base**: Minimum number of tasks that must use this provider before distributing by weight

**Example Distribution:**
```
capacity_providers = ["FARGATE", "FARGATE_SPOT"]
strategy = [
  { provider = "FARGATE",      weight = 1, base = 2 },  # First 2 tasks + 20% of remaining
  { provider = "FARGATE_SPOT", weight = 4, base = 0 }   # 80% of remaining tasks
]
```
Result: First 2 tasks on Fargate, then 1:4 ratio (20% Fargate, 80% Spot)

### Task Definition

Defines the blueprint for your containerized application - what image to use, how much CPU/memory, volumes, networking, etc.

**Core Configuration:**
- **family**: Name/version family for the task definition
- **cpu**: Task-level CPU units (required for Fargate)
- **memory**: Task-level memory in MB (required for Fargate)
- **container_definitions**: JSON string defining containers, ports, environment variables
- **network_mode**: 
  - `awsvpc` - Each task gets its own ENI (required for Fargate)
  - `bridge` - Default for EC2, uses Docker bridge
  - `host` - Task uses host network directly
  - `none` - No external network

**Volumes:**
- **Docker Volumes**: Managed by Docker engine, shared between containers in same task
- **EFS Volumes**: AWS managed network file system, works with Fargate and EC2, persistent across task restarts
- **Host Paths**: EC2 only, mounts directory from host instance

**Placement Constraints** (EC2 only):

Configured via a dynamic block — the block iterates over the list when provided, and is omitted when `null`.

- **type** (`string`, required): The constraint type.
  - `memberOf` — Tasks run only on instances matching the given expression (e.g., `"attribute:ecs.instance-type =~ t3.*"`).
  - `distinctInstance` — Each task runs on a different container instance.
- **expression** (`string`, optional): A cluster query language expression. Required for `memberOf`, not used with `distinctInstance`.

```hcl
# Task definition placement constraints
placement_constraints = [
  {
    type       = "memberOf"
    expression = "attribute:ecs.instance-type =~ t3.*"
  }
]
```

**Runtime Platform:**
- Specifies OS and CPU architecture
- Examples: LINUX/X86_64, LINUX/ARM64, WINDOWS_SERVER_2019_FULL/X86_64

### ECS Service

Runs and maintains the desired number of tasks from your task definition. Handles scheduling, load balancing, health checks, and deployment strategies.

**Service Configuration:**
- **desired_count**: Number of task copies to keep running
- **launch_type**: `FARGATE`, `EC2`, or `null` (to use capacity provider strategy)
- **scheduling_strategy**: 
  - `REPLICA` - Maintains desired count (default)
  - `DAEMON` - Runs exactly one task per EC2 instance

**Deployment Settings:**
- **deployment_maximum_percent**: Max % of desired tasks during deployment (e.g., 200% = can double temporarily)
- **deployment_minimum_healthy_percent**: Min % that must stay healthy (e.g., 100% = zero downtime)
- **deployment_circuit_breaker**: Automatically rolls back failed deployments

**Deployment Circuit Breaker** (optional):

Configured via a Terraform dynamic block — the block is only rendered when `deployment_circuit_breaker` is set (not `null`).

- **enable** (`bool`): Turns the circuit breaker on or off. When enabled, ECS monitors deployments and stops launching new tasks if they repeatedly fail to reach a healthy state.
- **rollback** (`bool`): If `true`, ECS automatically rolls back to the last stable deployment when the circuit breaker triggers.

```hcl
deployment_circuit_breaker = {
  enable   = true
  rollback = true
}
```

**Deployment Controller** (optional):

Also configured via a dynamic block — omitted entirely when set to `null`.

- **type** (`string`): The deployment strategy to use. Valid values:
  - `ECS` — Standard rolling update (default)
  - `CODE_DEPLOY` — Blue/green deployment via AWS CodeDeploy
  - `EXTERNAL` — Third-party deployment controller

```hcl
deployment_controller = {
  type = "ECS"
}
```

> **Note:** Both blocks use the Terraform idiom `for_each = var != null ? [var] : []` to make them optional. When the variable is `null`, the block is omitted; when set, it is rendered exactly once with the provided values.

**Load Balancer Integration:**
- Connects tasks to ALB/NLB target groups
- Routes traffic to container port specified
- Health check grace period prevents premature task termination

**Network Configuration** (required for awsvpc mode):
- **subnets**: Which VPC subnets to place tasks in
- **security_groups**: Firewall rules for task networking
- **assign_public_ip**: Whether tasks get public IPs (for internet access)

**Service Discovery:**
- Registers tasks with AWS Cloud Map
- Enables DNS-based service-to-service communication
- Format: `service-name.namespace`

**Placement Constraints** (EC2 only, optional):

Same concept as task definition placement constraints, but applied at the **service** level to control where tasks are placed across container instances. Configured via a dynamic block that iterates over the list.

- **type** (`string`, required):
  - `memberOf` — Place tasks only on instances matching the expression.
  - `distinctInstance` — Spread each task across separate container instances.
- **expression** (`string`, optional): Cluster query language expression (required for `memberOf`).

```hcl
# Service-level placement constraints
placement_constraints = [
  {
    type       = "distinctInstance"
  },
  {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-east-1a, us-east-1b]"
  }
]
```

**Ordered Placement Strategy** (EC2 only, optional):

Defines the strategy ECS uses to select container instances for task placement, evaluated in order. Configured via a dynamic block.

- **type** (`string`, required):
  - `binpack` — Place tasks to minimize the number of instances in use (pack tightly). Specify `field` as `cpu` or `memory`.
  - `spread` — Distribute tasks evenly. Specify `field` as an instance attribute (e.g., `attribute:ecs.availability-zone`) or `instanceId`.
  - `random` — Place tasks randomly. No `field` needed.
- **field** (`string`, optional): The attribute to apply the strategy against.

```hcl
# Pack by memory first, then spread across AZs
ordered_placement_strategy = [
  {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  },
  {
    type  = "binpack"
    field = "memory"
  }
]
```

**ECS Exec:**
- `enable_execute_command = true` - Allows interactive shell access to running containers
- Must also configure at cluster level with encryption/logging settings

### Launch Template (EC2 Only)

Defines the configuration for EC2 instances that will run your ECS tasks.

**Key Components:**
- **image_id**: ECS-optimized AMI (Amazon Linux 2 or Windows)
  - Must have ECS agent pre-installed
  - Get latest: `aws ssm get-parameter --name /aws/service/ecs/optimized-ami/amazon-linux-2/recommended`
- **instance_type**: EC2 size (e.g., t3.medium, m5.large)
- **user_data**: Startup script that registers instance with ECS cluster
  ```bash
  #!/bin/bash
  echo ECS_CLUSTER=my-cluster >> /etc/ecs/ecs.config
  ```

**IAM Instance Profile:**
- Allows EC2 instance to:
  - Pull container images from ECR
  - Write logs to CloudWatch
  - Register itself with ECS cluster
  - Fetch secrets from Parameter Store/Secrets Manager

**Block Device Mappings:**
- EBS volumes attached to instances
- Recommended: 30GB+ for container images and logs
- **encrypted**: Should be true for compliance
- **volume_type**: gp3 (recommended), gp2, io1, io2
- **iops/throughput**: Performance tuning for gp3/io volumes

**Monitoring:**
- Detailed monitoring = 1-minute CloudWatch metrics (vs 5-minute default)
- Additional cost but better visibility

### Auto Scaling Group (EC2 Only)

Manages the pool of EC2 instances that host your ECS tasks.

**Capacity Settings:**
- **min_size**: Minimum instances (always running)
- **max_size**: Maximum instances (scale limit)
- **desired_capacity**: Target instance count

**Health Checks:**
- **health_check_type**:
  - `EC2` - Instance-level health (is VM running?)
  - `ELB` - Load balancer health checks (is app responding?)
- **health_check_grace_period**: Time before starting health checks (allows instance startup time)

**Termination Policies:**
- `Default` - Balanced across AZs, then oldest launch template, then closest to billing hour
- `OldestInstance` - Terminates oldest instances first
- `NewestInstance` - Terminates newest instances first
- `OldestLaunchConfiguration` - Terminates instances from oldest launch config

**protect_from_scale_in:**
- When true, prevents ASG from terminating instances
- Used with ECS Capacity Provider managed scaling (ECS controls scale-in)

### ECS Capacity Provider (EC2 Only)

Links your Auto Scaling Group to the ECS cluster and enables ECS-managed auto-scaling.

**Key Difference from Fargate:**
- Fargate: AWS manages all infrastructure
- EC2 Capacity Provider: You own instances, ECS auto-scales them based on task demand

**How It Works:**
1. ECS monitors task placement needs
2. If insufficient capacity, ECS scales up ASG
3. If excess capacity, ECS scales down ASG
4. `target_capacity` controls how aggressively to pack tasks

**Managed Scaling Settings:**
- **target_capacity**: Target % of cluster capacity to use (e.g., 100 = fully utilized, 80 = leave 20% buffer)
- **minimum_scaling_step_size**: Minimum instances to add per scale event
- **maximum_scaling_step_size**: Maximum instances to add per scale event
- **instance_warmup_period**: Time (seconds) to wait for new instance before placing tasks

**Managed Termination Protection:**
- `ENABLED` - Prevents terminating instances with running tasks
- `DISABLED` - Can terminate any instance (tasks gracefully stopped first)

**Example Scaling Scenario:**
- You have 5 instances, each can run 10 tasks = 50 task capacity
- You scale service to 60 tasks
- ECS detects 10 task deficit
- Capacity provider adds 1 instance (10 task capacity)
- Tasks automatically placed on new instance

### Auto Scaling Policies (Optional)

Manual scaling policies typically triggered by CloudWatch alarms (e.g., high CPU, memory).

**When to Use:**
- Generally NOT needed if using ECS Capacity Provider managed scaling
- Use for custom scaling logic based on application metrics
- Use for predictive scaling based on time of day

**Adjustment Types:**
- `ChangeInCapacity` - Add/remove fixed number of instances
- `PercentChangeInCapacity` - Scale by percentage
- `ExactCapacity` - Set to specific instance count

**Cooldown Period:**
- Time to wait between scaling actions
- Prevents rapid scale up/down (flapping)

## IAM Roles Explained

### Task Role vs Execution Role

These are two distinct IAM roles with different purposes:

#### Task Role (`task_role_arn`)
**Used by:** Your application code running inside the container

**Grants permissions for:**
- Application runtime needs
- AWS service access from your code
- Example: Reading from S3, writing to DynamoDB, sending SQS messages

**Example Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::my-app-bucket/*"
    }
  ]
}
```

#### Execution Role (`execution_role_arn`)
**Used by:** ECS service (before your container starts)

**Grants permissions for:**
- Pulling Docker images from ECR
- Writing logs to CloudWatch Logs
- Fetching secrets from Secrets Manager or Parameter Store
- Creating ENIs for awsvpc networking

**Example Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

**Analogy:**
- **Execution Role** = Building manager's keys (to set up the apartment before you move in)
- **Task Role** = Your apartment keys (to use your stuff once you're living there)

### IAM Instance Profile (EC2 Only)

**Used by:** The EC2 instance hosting ECS tasks

**Grants permissions for:**
- Registering with ECS cluster
- Pulling container images from ECR
- Creating log groups in CloudWatch
- Communicating with ECS control plane

**Required Policies:**
- `AmazonEC2ContainerServiceforEC2Role` (AWS managed)

## Capacity Providers

### Overview

Capacity providers are the mechanism ECS uses to manage compute resources. There are two types:

### 1. Managed Capacity Providers (AWS-Owned)

**Available Providers:**
- `FARGATE` - Standard Fargate compute
- `FARGATE_SPOT` - Fargate Spot instances (up to 70% cheaper, can be interrupted)

**Characteristics:**
- No infrastructure management
- Pay per task runtime
- Instant scaling
- Just reference by name in your configuration

**When to Use:**
- Want serverless containers
- Variable/unpredictable workloads
- Don't want to manage EC2 instances

### 2. Custom EC2 Capacity Providers (You Create)

**Characteristics:**
- Backed by your Auto Scaling Group
- You manage EC2 instances
- ECS auto-scales instances based on task demand
- More control over instance types and configuration

**When to Use:**
- Need specific instance types (GPU, ARM, etc.)
- Want Reserved Instance pricing
- Require host-level security/compliance
- Need persistent storage or special networking

### Creating and Using EC2 Capacity Providers

**Step 1: Create the provider** (lines 363-442 in main.tf)
```hcl
resource "aws_ecs_capacity_provider" "ecs_ec2" {
  name = "my-ec2-provider"
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_ec2[0].arn
    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100
    }
  }
}
```

**Step 2: Associate with cluster** (lines 61-75 in main.tf)
```hcl
resource "aws_ecs_cluster_capacity_providers" "ecs" {
  capacity_providers = ["my-ec2-provider"]
}
```

**Step 3: Use in service**
```hcl
capacity_provider_strategy = [
  {
    capacity_provider = "my-ec2-provider"
    weight            = 1
    base              = 0
  }
]
```

## Fargate vs EC2 Launch Types

| Feature | Fargate | EC2 |
|---------|---------|-----|
| **Infrastructure Management** | AWS manages everything | You manage EC2 instances |
| **Pricing** | Pay per vCPU/GB-hour of task runtime | Pay for EC2 instances (even if idle) |
| **Scaling Speed** | Instant (no instance launch) | Slower (must launch EC2 instances) |
| **Cost Optimization** | Good for variable workloads | Better for steady-state workloads (use Reserved Instances) |
| **Instance Types** | Limited CPU/memory combinations | Any EC2 instance type |
| **Persistent Storage** | EFS only | EFS + Docker volumes + host paths |
| **Networking** | awsvpc only | awsvpc, bridge, host, none |
| **Windows Containers** | Limited support | Full support |
| **Compliance** | Shared tenant isolation | Can use Dedicated Hosts |
| **SSH / Host Access** | Not possible | Full host access |

### Choosing Between Fargate and EC2

**Choose Fargate when:**
- You want zero infrastructure management
- Workload is variable or unpredictable
- You need fast scaling
- Running microservices with small to medium CPU/memory
- Team has limited ops experience

**Choose EC2 when:**
- You need specific instance types (GPU, high memory, ARM)
- Running at scale with steady state (Reserved Instance savings)
- Need persistent storage beyond EFS
- Require host-level security controls
- Running Windows containers with advanced features
- Need to run DAEMON scheduling strategy

**Mix Both:**
- Use Fargate for most services (convenience)
- Use EC2 for specialized workloads (GPU, high memory)
- Distribute via capacity provider strategy

## Examples

### Example 1: Simple Fargate Service

```hcl
module "fargate_app" {
  source = "./modules/Deploy-ecs"
  
  ecs = {
    common = {
      account_name  = "mycompany"
      region_prefix = "use1"
      tags = {
        Environment = "dev"
      }
    }
    
    cluster_name               = "dev-cluster"
    container_insights_enabled = true
    
    task_definition = {
      family                   = "web-app"
      task_role_arn            = aws_iam_role.task.arn
      execution_role_arn       = aws_iam_role.execution.arn
      network_mode             = "awsvpc"
      requires_compatibilities = ["FARGATE"]
      cpu                      = "256"
      memory                   = "512"
      container_definitions    = jsonencode([
        {
          name      = "nginx"
          image     = "nginx:latest"
          cpu       = 256
          memory    = 512
          essential = true
          portMappings = [
            {
              containerPort = 80
              protocol      = "tcp"
            }
          ]
        }
      ])
    }
    
    service = {
      name                               = "web-service"
      desired_count                      = 2
      launch_type                        = "FARGATE"
      deployment_maximum_percent         = 200
      deployment_minimum_healthy_percent = 100
      
      network_configuration = {
        subnets          = ["subnet-abc", "subnet-def"]
        security_groups  = ["sg-web"]
        assign_public_ip = false
      }
      
      load_balancers = [
        {
          target_group_arn = aws_lb_target_group.web.arn
          container_name   = "nginx"
          container_port   = 80
        }
      ]
    }
  }
}
```

### Example 2: EC2 with Auto Scaling

```hcl
module "ec2_cluster" {
  source = "./modules/Deploy-ecs"
  
  ecs = {
    common = {
      account_name  = "mycompany"
      region_prefix = "use1"
      tags = {
        Environment = "prod"
      }
    }
    
    cluster_name = "prod-cluster"
    
    capacity_providers = {
      capacity_provider_names = ["prod-ec2-provider"]
      default_capacity_provider_strategy = [
        {
          capacity_provider = "prod-ec2-provider"
          weight            = 1
          base              = 0
        }
      ]
    }
    
    task_definition = {
      family                   = "api"
      task_role_arn            = aws_iam_role.task.arn
      execution_role_arn       = aws_iam_role.execution.arn
      network_mode             = "bridge"
      requires_compatibilities = ["EC2"]
      container_definitions    = jsonencode([...])
    }
    
    service = {
      name                  = "api-service"
      desired_count         = 5
      scheduling_strategy   = "REPLICA"
      
      capacity_provider_strategy = [
        {
          capacity_provider = "prod-ec2-provider"
          weight            = 1
          base              = 2
        }
      ]
    }
    
    ec2_autoscaling = {
      launch_template = {
        name                   = "ecs-instance"
        image_id               = "ami-0c55b159cbfafe1f0"  # ECS-optimized AMI
        instance_type          = "t3.medium"
        iam_instance_profile   = "ecsInstanceRole"
        user_data              = <<-EOF
          #!/bin/bash
          echo ECS_CLUSTER=prod-cluster >> /etc/ecs/ecs.config
        EOF
        
        block_device_mappings = [
          {
            device_name = "/dev/xvda"
            ebs = {
              volume_size = 30
              volume_type = "gp3"
              encrypted   = true
            }
          }
        ]
      }
      
      autoscaling_group = {
        name                 = "ecs-asg"
        min_size             = 2
        max_size             = 10
        desired_capacity     = 3
        vpc_zone_identifier  = ["subnet-abc", "subnet-def"]
        launch_template_version = "$Latest"
      }
      
      capacity_provider = {
        name = "prod-ec2-provider"
        managed_scaling = {
          status                    = "ENABLED"
          target_capacity           = 80
          minimum_scaling_step_size = 1
          maximum_scaling_step_size = 5
        }
      }
    }
  }
}
```

### Example 3: Mixed Fargate and Fargate Spot

```hcl
module "mixed_capacity" {
  source = "./modules/Deploy-ecs"
  
  ecs = {
    common = {
      account_name  = "mycompany"
      region_prefix = "use1"
      tags = {}
    }
    
    cluster_name = "mixed-cluster"
    
    capacity_providers = {
      capacity_provider_names = ["FARGATE", "FARGATE_SPOT"]
      default_capacity_provider_strategy = [
        {
          capacity_provider = "FARGATE"
          weight            = 1
          base              = 2
        },
        {
          capacity_provider = "FARGATE_SPOT"
          weight            = 4
          base              = 0
        }
      ]
    }
    
    task_definition = {
      family                   = "batch-processor"
      task_role_arn            = aws_iam_role.task.arn
      execution_role_arn       = aws_iam_role.execution.arn
      network_mode             = "awsvpc"
      requires_compatibilities = ["FARGATE"]
      cpu                      = "256"
      memory                   = "512"
      container_definitions    = jsonencode([...])
    }
    
    service = {
      name          = "batch-service"
      desired_count = 10
      
      network_configuration = {
        subnets          = ["subnet-abc", "subnet-def"]
        security_groups  = ["sg-batch"]
        assign_public_ip = false
      }
    }
  }
}
```
**Result:** First 2 tasks on Fargate, remaining 8 distributed 20% Fargate (1-2 tasks) and 80% Fargate Spot (6-7 tasks)

### Example 4: ECS Exec Enabled for Debugging

```hcl
module "debug_enabled" {
  source = "./modules/Deploy-ecs"
  
  ecs = {
    common = {
      account_name  = "mycompany"
      region_prefix = "use1"
      tags = {}
    }
    
    cluster_name = "debug-cluster"
    
    execute_command_configuration = {
      kms_key_id = aws_kms_key.ecs_exec.arn
      logging    = "OVERRIDE"
      
      log_configuration = {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = "/aws/ecs/exec/debug-cluster"
        s3_bucket_name                 = "ecs-exec-audit-logs"
        s3_bucket_encryption_enabled   = true
        s3_key_prefix                  = "exec-sessions/"
      }
    }
    
    task_definition = {
      family                   = "debug-app"
      task_role_arn            = aws_iam_role.task.arn
      execution_role_arn       = aws_iam_role.execution.arn
      network_mode             = "awsvpc"
      requires_compatibilities = ["FARGATE"]
      cpu                      = "256"
      memory                   = "512"
      container_definitions    = jsonencode([...])
    }
    
    service = {
      name                   = "debug-service"
      desired_count          = 1
      launch_type            = "FARGATE"
      enable_execute_command = true
      
      network_configuration = {
        subnets          = ["subnet-abc"]
        security_groups  = ["sg-debug"]
        assign_public_ip = false
      }
    }
  }
}
```

**Usage:**
```bash
# Get task ID
TASK_ID=$(aws ecs list-tasks --cluster debug-cluster --service debug-service --query 'taskArns[0]' --output text)

# Execute interactive shell
aws ecs execute-command \
  --cluster debug-cluster \
  --task $TASK_ID \
  --container debug-app \
  --interactive \
  --command "/bin/bash"
```

## Outputs

This module provides the following outputs:

- `ecs_cluster_id` - ECS cluster ID
- `ecs_cluster_arn` - ECS cluster ARN
- `ecs_cluster_name` - ECS cluster name
- `ecs_task_definition_arn` - Task definition ARN
- `ecs_service_id` - ECS service ID
- `ecs_service_name` - ECS service name
- `launch_template_id` - Launch template ID (if EC2)
- `autoscaling_group_id` - ASG ID (if EC2)
- `capacity_provider_id` - Capacity provider ID (if EC2)

## Requirements

- Terraform >= 1.0
- AWS Provider >= 4.0

## Notes

- For Fargate, `network_mode` must be `awsvpc`
- Task role and execution role are different - see [IAM Roles Explained](#iam-roles-explained)
- EC2 launch type requires ECS-optimized AMI with ECS agent
- Container Insights incurs additional CloudWatch charges
- ECS Exec requires appropriate IAM permissions for KMS, CloudWatch, and S3
- Fargate Spot can be interrupted with 2-minute warning
