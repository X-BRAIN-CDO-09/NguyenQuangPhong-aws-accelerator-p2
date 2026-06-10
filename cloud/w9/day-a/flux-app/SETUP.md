# Flux Setup Guide

## Prerequisites

- Kubernetes cluster running
- `flux` CLI installed:
  ```bash
  curl -s https://fluxcd.io/install.sh | sudo bash
  flux --version
  ```
- GitHub personal access token with `repo` scope:
  - Go to GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
  - Repo permissions: `Contents: read/write`, `Pull requests: read/write`
  - Save the token

---

## Step 1: Bootstrap Flux

This installs Flux into your cluster and creates the first sync:

```bash
flux bootstrap github \
  --owner=NguyenQuangPhong \
  --repository=NguyenQuangPhong-aws-accelerator-p2 \
  --branch=main \
  --path=cloud/w9/day-a/flux-app \
  --personal
```

- `--owner` — your GitHub username
- `--repository` — repo name
- `--path` — folder Flux will watch (creates it if doesn't exist)
- `--personal` — single user (no org)
- `--token-auth` — use if PAT doesn't work via SSH

It will prompt for your GitHub token (or use `GITHUB_TOKEN` env var).

### What bootstrap does

| Step | What happens |
|------|-------------|
| 1 | Creates GitHub deploy key in your repo |
| 2 | Creates namespace `flux-system` in cluster |
| 3 | Installs Flux CRDs + controllers |
| 4 | Creates `GitRepository` CRD pointing to your repo path |
| 5 | Creates `Kustomization` CRD pointing to that folder |
| 6 | Syncs cluster state to match folder |

---

## Step 2: Verify Flux is Running

```bash
flux check                     # Health check
kubectl get pods -n flux-system  # Should show controllers running
flux get kustomizations        # List synced kustomizations
```

---

## Step 3: Add Your Manifests

Create the same nginx app in `flux-app/k8s/`:

```
flux-app/
└── k8s/
    └── kustomization.yaml       # Just holds namespace
```

But wait — with Flux, the `Kustomization` CRD is what tells Flux to sync, and it reads the YAML files inside the `--path` folder. So you can put raw manifests directly there:

```
flux-app/
├── deployment.yaml
├── service.yaml
└── kustomization.yaml
```

No separate Application CRD needed — Flux creates a default `Kustomization` during bootstrap.

### flux-app/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
```

Copy your `deployment.yaml` and `service.yaml` from the my-app project.

---

## Step 4: Push and Watch it Sync

```bash
git add cloud/w9/day-a/flux-app/
git commit -m "[W9-D1] Add Flux app manifests"
git push origin main
```

Flux reconciles every few minutes automatically. Or force a sync:

```bash
flux reconcile kustomization flux-app
```

Check status:

```bash
flux get kustomizations
kubectl get pods
```

---

## Step 5: Test a Change (PR + Merge)

Flux doesn't have a "plan on PR" built in — you use `flux diff` manually:

```bash
# Create a branch, make change
git checkout -b test-flux
# edit deployment.yaml replicas: 3
git add .
git commit -m "Test change"

# Preview what will change
flux diff kustomization flux-app --path cloud/w9/day-a/flux-app

# Merge
git checkout main
git merge test-flux
git push origin main
```

Flux auto-syncs the merge.

---

## Comparing ArgoCD vs Flux

| Action | ArgoCD | Flux |
|--------|--------|------|
| Install | `kubectl apply -f manifests` | `flux bootstrap` |
| Watch a repo folder | `Application` CRD (must create manually) | `GitRepository` + `Kustomization` CRDs (created by bootstrap) |
| Sync | Auto-sync in CRD or manual `argocd app sync` | Auto-reconciliation every few minutes |
| Force sync | `argocd app sync my-app` | `flux reconcile kustomization flux-app` |
| Diff/plan on PR | GitHub Actions on pull_request | GitHub Actions with `flux diff` |
| UI | Built-in web UI | No UI (CLI only) |
| Rollback | `git revert` + auto-sync | `git revert` + auto-reconcile |
| Key feeling | "I manage a CRD that points to my code" | "I bootstrap once, then just push code" |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Bootstrap fails (auth) | `export GITHUB_TOKEN=ghp_xxx` before running |
| Nothing deploys | `flux get kustomizations` to check status |
| Flux says "stuck" | `flux events --watch` to see errors |
| Resources not updating | Check file path matches `--path` exactly |
| Want to uninstall Flux | `flux uninstall` |

---

## What You Practiced

| Skill | How |
|-------|-----|
| Flux bootstrap | Install Flux into cluster |
| GitRepository CRD | Flux watches a git path |
| Kustomization CRD | Flux syncs YAML to cluster |
| Reconciliation | Auto-sync on push |
| flux diff | Preview changes before merge |
