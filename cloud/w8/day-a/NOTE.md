# [W8-D1] Terraform Fundamentals

## 1. Core Workflow
Standard lifecycle for managing infrastructure:

| Command | Action | Description |
| :--- | :--- | :--- |
| `terraform init` | **Initialize** | Prepares directory, downloads providers/modules, sets up backend. |
| `terraform fmt` | **Format** | Rewrites HCL files to canonical format and style. |
| `terraform validate` | **Validate** | Checks configuration for syntax and internal consistency. |
| `terraform plan` | **Plan** | Generates execution plan; previews changes without applying them. |
| `terraform apply` | **Apply** | Executes changes; updates `terraform.tfstate`. |
| `terraform destroy` | **Destroy** | Removes all remote objects managed by the configuration. |

## 2. State Management (Basics)
Terraform tracks managed infrastructure in `terraform.tfstate`.

- `terraform show`: High-level view of the current state or plan.
- `terraform state list`: List all resources currently in the state file.
- `terraform state show <ADDR>`: Detailed attributes of a specific resource.

## 3. HCL Syntax Components
Key building blocks of a `.tf` file:

- **`provider`**: Configures the platform (AWS, Azure, GCP).
- **`resource`**: Defines an infrastructure object (e.g., `aws_instance`).
- **`data`**: Queries information from APIs outside the current configuration (read-only).
- **`variable`**: Input values to parameterize configurations.
- **`output`**: Return values of a module/configuration for use elsewhere.

## 4. Key Differences: Data vs Resource
- **`resource "type" "name"`**: Manages lifecycle (Create, Update, Delete).
- **`data "type" "name"`**: Fetches existing data; does not create or modify resources.

## 5. Implementation Notes
- **Best Practice:** Keep provider config and primary resources in `main.tf`.
- **Modularity:** Use `variables.tf` for inputs and `outputs.tf` for data exposure.
- **Validation:** Always run `terraform fmt` and `terraform validate` before committing.
- **Security:** Never commit sensitive provider credentials (use ENV vars or IAM roles).
