# [W8-D3] Terraform State Management, Modules & Best Practices

## 1. Remote State Management

Local state (`terraform.tfstate`) works for solo dev. Teams need a **remote backend**.

| Backend | Pros | Cons |
| :--- | :--- | :--- |
| **S3** | Cheap, encrypted, versioned | No built-in locking |
| **S3 + DynamoDB** | Adds state locking | Slightly more setup |
| **Terraform Cloud** | UI, RBAC, remote runs | Paid for teams |

### S3 + DynamoDB Locking (industry standard)

- **S3** stores the state file (enable versioning for rollback).
- **DynamoDB** holds a lock record so two people cannot `apply` at the same time.
- **Flow:** Before `apply`, Terraform calls DynamoDB `PutItem` to acquire lock → deploy → `DeleteItem` to release. If lock is held, `PutItem` fails with "Error acquiring the state lock".

### State CLI Commands

| Command | What it does |
| :--- | :--- |
| `terraform state list` | List all resources in state |
| `terraform state show <ADDR>` | Show details of one resource |
| `terraform state mv <SRC> <DST>` | Rename/move a resource in state |
| `terraform state rm <ADDR>` | Remove from state (does NOT destroy infrastructure) |
| `terraform state pull` | Download current state to stdout |

> **Never edit `terraform.tfstate` by hand.** Always use CLI commands.

---

## 2. Modules

Modules are **reusable, composable** Terraform configurations.

### Module Sources

| Source | Example |
| :--- | :--- |
| **Local** | `source = "./modules/ec2-instance"` |
| **Registry** | `source = "terraform-aws-modules/vpc/aws"` |
| **Git** | `source = "git::https://github.com/...//modules/vpc"` |

### Module Structure Convention

```
modules/ec2-instance/
  main.tf       # resources
  variables.tf  # inputs (type + description)
  outputs.tf    # outputs
```

### Input-Only Contract

A module should **only** reference:
- Its own input variables (`var.xxx`)
- Data sources (if needed)

It should **never** read `var` from root — everything must be passed explicitly through module arguments.

### Why Modules?

| Problem | Solution |
| :--- | :--- |
| Same EC2 config repeated 10x | Module once, call 10x with different inputs |
| Dev uses t2.micro, prod uses t2.large | `instance_type` as variable |
| Team needs consistent infra | Shared internal modules enforce standards |
| Complex resource (VPC with 50+ sub-resources) | Use community module from Registry |

---

## 3. ADR (Architecture Decision Record)

ADR documents **why** a decision was made — not what.

### Template

```markdown
# ADR-001: Title

**Date:** YYYY-MM-DD

**Context:** What is the problem? What options were considered?

**Decision:** What was chosen and why.

**Consequences:**
+ Pros
- Cons
```

### Why ADR?
- **Context retention:** New members read ADRs instead of asking "why did we pick this?"
- **Avoid re-debate:** No need to re-argue decisions every few months.
- **Accountability:** Each ADR has a date and author.
- **Evolution:** When context changes, write a new ADR superseding the old one.

---

## 4. Best Practices

### Security
- **Never commit credentials** — use environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) or IAM roles.
- **Never commit `.terraform/`** — contains provider binaries.
- **Never commit `*.tfstate`** — contains sensitive data (IPs, IDs, secrets).
- Use `sensitive = true` on variables that hold secrets.

### Gitignore for Terraform
```
.terraform/
*.tfstate
*.tfstate.backup
crash.log
override.tf
```

### Environment Separation
Each environment (dev/staging/prod) should have its own:
- Directory (or workspace)
- Backend config (different S3 bucket/key)
- Variables

### Production Workflow
```
1. terraform init      # Init backend + download modules
2. terraform fmt       # Format code
3. terraform validate  # Syntax + internal checks
4. terraform plan      # Peer review changes
5. terraform apply     # Deploy (after review)
6. terraform state list # Verify state
```
