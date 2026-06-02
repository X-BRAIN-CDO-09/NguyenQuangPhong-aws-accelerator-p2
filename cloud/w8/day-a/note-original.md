# Original NOTE.md (Before Polish)

```markdown
# data "resourceType" "resourceName"
# resource.resourceType.resourceName == resourceAddress (ex: data.aws_ami.ubuntu)

# FLOWS:
# 1. terraform fmt
# 2. terraform init
# 3. aws configure list
# 4. terraform apply
# DAY1's notes

## Terraform commands

- `terraform init` (init the working directory, also downloads required providers) -> Creates `.terraform.lock.hcl`
- `terraform fmt` (format the configuration)
- `terraform validate` (validate the configuration, basically checks for syntax errors)
- `terraform plan` (plan the configuration)
- `terraform apply` (apply the configuration) -> After applied: Terraform writes data about infrastructure to the state file called `terraform.tfstate`
- `terraform destroy` (destroy the configuration)
- `terraform state list` (list the resources in the state)
- `terraform state show <resourceAddress>` (show the details of a resource in the state)
- `terraform show` (Print out workspace's entire state)

## Data sources vs resources

- `data "resourceType" "resourceName"`
- `resource.resourceType.resourceName` == `resourceAddress` (ex: `data.aws_ami.ubuntu`)

## Module


## Terraform plan
- terraform plan -var instance_type=t2.large: Is gonna plan the configuration with `t2.large` instance type

## HCL Basics
- resource
- provider
- variable 

## Recommendations

- When write a new Terraform configuration, recommend defining provider blocks and other primary infrastructure in `main.tf` as best practice.
- When defining resources, use `resource.resourceType.resourceName` syntax to refer to resources by their address.

```
provider "aws" {
  region = "us-west-2"
}
```
```

# Change Log (Polishing)
- **Formatting:** Converted raw lists into a structured Markdown table for the core workflow.
- **Organization:** Grouped commands and concepts into logical sections (Workflow, State, HCL Components).
- **Clarity:** Refined descriptions for technical accuracy and brevity.
- **Best Practices:** Formalized the "Recommendations" section into an "Implementation Notes" section.
- **Cleanup:** Removed empty sections (e.g., "Module") and duplicated content.
