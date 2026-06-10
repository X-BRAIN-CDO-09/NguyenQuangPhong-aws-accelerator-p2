# Day A Knowledge: GitOps & CI/CD

---

## 1. GitOps Principles

| Principle | Meaning |
|-----------|---------|
| Declarative | Desired state defined in files (not imperative commands) |
| Versioned | All changes go through git (audit trail) |
| Pull-based | Operator in cluster pulls from repo (vs push from CI) |
| Reconciled | Cluster state continuously compared to repo state |

**The flow:**
```
Developer pushes to git
  → ArgoCD detects change
    → ArgoCD syncs cluster to match repo
```

---

## 2. GitHub Actions — Plan on PR / Apply on Merge

### Two workflow triggers

| Workflow | Trigger | Action |
|----------|---------|--------|
| `plan.yml` | `on: pull_request` | Preview changes, dry-run |
| `apply.yml` | `on: push: branches: [main]` | Actually deploy |

### Workflow structure

```yaml
name: Workflow Name
on:                          # When to run
  pull_request:
    branches: [main]
jobs:
  job-name:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4   # Clone repo
      - run: some-command           # Do something
```

### Key concepts

- **`on.pull_request`** — runs on PR open, sync, reopen
- **`on.push.branches: [main]`** — runs when PR merges to main
- **`actions/checkout`** — clones your repo into the runner
- **`${{ secrets.X }}`** — secure values set in GitHub UI
- **`environment: production`** — adds approval gate before apply runs

---

## 3. Kustomize

### What it does

Kustomize transforms raw YAML without templating. It takes base manifests and applies overlays/patches.

### Key features

| Feature | Purpose |
|---------|---------|
| `resources` | List of YAML files to combine |
| `commonLabels` | Inject labels into all resources (metadata + selectors) |
| `commonAnnotations` | Inject annotations into all resources |
| `namePrefix` / `nameSuffix` | Rename resources (e.g., `my-app` → `kustomize-my-app-prod-v1`) |
| `namespace` | Override namespace for all resources |

### How it injects labels

| Resource | Where labels go |
|----------|----------------|
| Deployment | `metadata.labels`, `spec.selector.matchLabels`, `spec.template.metadata.labels` |
| Service | `metadata.labels`, `spec.selector` |
| All others | `metadata.labels` |

### Usage

```bash
kustomize build k8s/      # Render final YAML to stdout
kubectl apply -k k8s/     # Build + apply in one command
```

---

## 4. ArgoCD

### What it is

A GitOps operator that runs in your cluster. It watches a git repo and syncs the cluster state to match.

### Application CRD fields

| Field | Purpose |
|-------|---------|
| `source.repoURL` | Git repo to watch (must end in `.git`) |
| `source.targetRevision` | Branch/tag/commit (`HEAD`, `main`, `v1.0`) |
| `source.path` | Subdirectory with manifests |
| `destination.server` | Target cluster (usually `https://kubernetes.default.svc`) |
| `destination.namespace` | Namespace to deploy into |
| `syncPolicy.automated.prune` | Delete resources removed from repo |
| `syncPolicy.automated.selfHeal` | Revert manual changes to match repo |

### How it works

```
ArgoCD polls git repo (or receives webhook)
  → Compares manifest vs cluster state
    → If drift detected: syncs cluster to match manifest
```

### Sync strategies

| Strategy | Behavior |
|----------|----------|
| Manual | You click "Sync" in UI or CLI |
| Auto-sync | Syncs automatically on every change |
| Auto-prune | Deletes resources removed from repo |
| Self-heal | Reverts manual `kubectl edit` changes |

### Common CLI commands

```bash
argocd app list                              # List applications
argocd app get my-app                        # Show app status
argocd app sync my-app                       # Trigger sync
argocd app sync my-app --prune               # Sync + delete removed resources
argocd app diff my-app                       # Show drift
argocd account generate-token                # Create token for CI
```

---

## 5. Rollback

### Two approaches

| Method | When to use |
|--------|-------------|
| `git revert` (commit) | Revert the code + ArgoCD auto-syncs |
| `kubectl rollout undo` | Quick revert without touching git (but ArgoCD self-heal will revert back) |

### Git revert (GitOps way)

```bash
git revert <commit-hash>   # Creates new commit that undoes changes
git push origin main       # ArgoCD sees change, syncs cluster back
```

ArgoCD self-heal will undo any manual `kubectl rollout undo` — so **always use `git revert`** in a GitOps setup.

---

## 6. App-of-Apps Pattern

A single ArgoCD Application that deploys other Applications:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
spec:
  source:
    repoURL: <repo>
    path: argocd/apps    # Folder with many Application YAMLs
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
```

Then in `argocd/apps/`:
```
argocd/apps/
├── my-app.yaml
├── monitoring.yaml
└── ingress.yaml
```

Useful when you have many services to deploy.

---

## 7. Sync Waves

Control the **order** of resource creation:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"   # Lower = applied first
```

| Wave | Typical resources |
|------|-------------------|
| -5 | CRDs, Namespaces |
| 0 | ConfigMaps, Secrets |
| 1 | PersistentVolumeClaims |
| 5 | Deployments, Services |
| 10 | Ingresses |

Without sync waves, all resources apply in parallel.

---

## 8. Full Day-A Flow

```
Developer:

  1. Create branch
  2. Edit k8s manifests
  3. Open PR
      → GitHub Actions runs plan.yml
        → Shows rendered YAML in PR
  4. Merge PR to main
      → GitHub Actions runs apply.yml
        → Calls argocd app sync
      → ArgoCD detects change in repo
        → Syncs cluster state to match
  5. Need to rollback?
      → git revert <commit>
      → ArgoCD auto-syncs to previous state
```

---

## References

- [GitHub Actions workflow syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Kustomize reference](https://kubectl.docs.kubernetes.io/references/kustomize/)
- [ArgoCD docs](https://argo-cd.readthedocs.io/)
- [ArgoCD Application spec](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#applications)
- [ArgoCD sync waves](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/)
- [GitOps principles](https://opengitops.dev/)
