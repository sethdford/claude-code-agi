# Terraform Conventions

This preset covers best practices for Terraform infrastructure code with modules, state management, and safety patterns.

## Module Organization

Organize Terraform into modules by feature or environment.

**Pattern:**

```
infrastructure/
├── main.tf              # Root module, orchestration
├── variables.tf         # Root inputs
├── outputs.tf           # Root outputs
├── terraform.tfvars     # Variable values (don't commit)
├── terraform.tfvars.example
├── .terraform/          # Generated (gitignored)
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── database/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev/
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── prod/
│       ├── terraform.tfvars
│       └── backend.tf
└── .gitignore
```

Each module is self-contained with clear inputs and outputs.

## State Management

Always use remote backends. Never commit `terraform.tfstate` files.

**Pattern (GCP):**

```hcl
terraform {
  backend "gcs" {
    bucket  = "my-org-terraform-state"
    prefix  = "prod"
    encryption_key = "..."  # From GCP KMS
  }

  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.region
}
```

**Pattern (AWS):**

```hcl
terraform {
  backend "s3" {
    bucket         = "my-org-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
}
```

Backend configuration can be externalized to `backend-config` files:

```bash
terraform init -backend-config="bucket=my-bucket" -backend-config="key=prod/state"
```

Never commit `.terraform/` or `*.tfstate`. Add to `.gitignore`:

```
.terraform/
*.tfstate
*.tfstate.*
.terraform.lock.hcl  # Optional: version control this for reproducibility
```

## Variable Naming

Use clear, hierarchical naming.

**Pattern (variables.tf):**

```hcl
variable "gcp_project_id" {
  type        = string
  description = "GCP project ID"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.gcp_project_id))
    error_message = "Project ID must be lowercase alphanumeric with hyphens."
  }
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "compute_instances" {
  type = object({
    count       = number
    machine_type = string
    disk_size_gb = number
  })
  description = "Compute instance configuration"
  default = {
    count        = 2
    machine_type = "e2-medium"
    disk_size_gb = 50
  }
}

variable "labels" {
  type        = map(string)
  description = "Common labels applied to all resources"
  default = {
    managed_by = "terraform"
    team       = "platform"
  }
}
```

Always include `validation` blocks for important variables.

## Output Patterns

Export only what downstream code needs.

**Pattern (outputs.tf):**

```hcl
output "vpc_id" {
  value       = google_compute_network.main.id
  description = "VPC network ID"
  sensitive   = false
}

output "database_connection_string" {
  value       = "postgresql://${google_sql_database_instance.main.connection_name}"
  description = "Database connection string for applications"
  sensitive   = true  # Don't expose in logs
}

output "load_balancer_ip" {
  value       = google_compute_forwarding_rule.main.ip_address
  description = "Load balancer public IP"
}
```

Keep outputs minimal. Only export what other modules or applications need.

## Safety Best Practices

**Always plan before apply:**

```bash
terraform plan -out=tfplan                # Generate plan
terraform show tfplan                     # Review changes
terraform apply tfplan                    # Apply only planned changes
```

Never run `terraform apply` without reviewing `terraform plan` first.

**Use workspaces for environment isolation:**

```bash
terraform workspace list
terraform workspace new staging
terraform workspace select staging
terraform apply
```

**Enable backend state locking to prevent concurrent changes:**

```hcl
terraform {
  backend "gcs" {
    bucket = "my-terraform-state"
  }
}
```

GCS and S3 backends have built-in locking.

## Drift Detection

Detect and reconcile infrastructure drift regularly.

**Pattern:**

```bash
terraform refresh              # Fetch current state
terraform plan -refresh-only   # Show differences without changes
```

Add to CI to detect drift automatically:

```bash
terraform plan -detailed-exitcode
# Exit codes: 0 = no changes, 1 = error, 2 = changes detected
```

## Module Usage

**Pattern (root main.tf):**

```hcl
module "vpc" {
  source = "./modules/vpc"

  project_id     = var.gcp_project_id
  region         = var.region
  environment    = var.environment
  cidr_block     = "10.0.0.0/16"
  labels         = var.labels
}

module "compute" {
  source = "./modules/compute"

  project_id  = var.gcp_project_id
  region      = var.region
  vpc_id      = module.vpc.vpc_id
  subnet_id   = module.vpc.subnet_id
  environment = var.environment
  labels      = var.labels

  depends_on = [module.vpc]
}

module "database" {
  source = "./modules/database"

  project_id        = var.gcp_project_id
  region            = var.region
  environment       = var.environment
  backup_location   = var.database_backup_location
  labels            = var.labels
}
```

**Module interface (modules/vpc/outputs.tf):**

```hcl
output "vpc_id" {
  value       = google_compute_network.main.id
  description = "VPC network ID for references"
}

output "subnet_id" {
  value       = google_compute_subnetwork.main.id
  description = "Subnet ID for compute instances"
}
```

Always declare dependencies explicitly with `depends_on` when needed.

## Common Mistakes

1. **Committing `terraform.tfstate`** — Always use remote backend
2. **Applying without plan review** — Always review `terraform plan` output
3. **Hardcoding values** — Use variables and locals
4. **No state locking** — Use backends with built-in locking
5. **Monolithic root modules** — Always organize into modules by feature
