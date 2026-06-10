# Day A Practical Project: GitHub Actions + ArgoCD

## Project: Deploy nginx via GitOps

You'll create a GitHub repo where:
- **PR** → GitHub Actions shows what will change
- **Merge to main** → GitHub Actions tells ArgoCD to sync
- **ArgoCD** watches the repo and applies to Kubernetes

---

## Step 1: Create Repo

Create `my-app` on GitHub (public or private). Clone it:

```bash
git clone https://github.com/YOUR_USERNAME/my-app.git
cd my-app
```

---

## Step 2: Add K8s Manifests

Create `k8s/` folder with app manifests:

```
my-app/
└── k8s/
    ├── deployment.yaml
    ├── service.yaml
    └── kustomization.yaml
```

### k8s/deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

### k8s/service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

### k8s/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
- service.yaml
```

---

## Step 3: Add GitHub Actions Workflows

Create:

```
my-app/
└── .github/workflows/
    ├── plan.yml
    └── apply.yml
```

### .github/workflows/plan.yml

```yaml
name: Plan on PR

on:
  pull_request:
    branches: [main]

jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Show rendered manifests
        run: |
          echo "# Rendered K8s manifests"
          cat k8s/*.yaml
```

### .github/workflows/apply.yml

```yaml
name: Apply on Merge

on:
  push:
    branches: [main]

jobs:
  apply:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - name: Trigger ArgoCD sync
        env:
          ARGOCD_SERVER: ${{ secrets.ARGOCD_SERVER }}
          ARGOCD_AUTH_TOKEN: ${{ secrets.ARGOCD_TOKEN }}
        run: |
          curl -sSL -o /tmp/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
          chmod +x /tmp/argocd
          /tmp/argocd login $ARGOCD_SERVER --auth-token $ARGOCD_TOKEN --grpc-web
          /tmp/argocd app sync my-app --prune --grpc-web
```

---

## Step 4: Add ArgoCD Manifests

Create:

```
my-app/
└── argocd/
    └── application.yaml
```

### argocd/application.yaml

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/my-app.git
    targetRevision: HEAD
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Replace `YOUR_USERNAME` with your actual GitHub username.

---

## Step 5: Push Everything

```bash
git add .
git commit -m "[W9-D1] GitOps setup: nginx app + ArgoCD + GitHub Actions"
git push origin main
```

---

## Step 6: Apply ArgoCD App (one-time)

If you have kubectl access to your cluster:

```bash
kubectl apply -f argocd/application.yaml
```

Now ArgoCD watches your repo and syncs automatically.

---

## Step 7: Set Up GitHub Secrets

Go to **Settings → Secrets and variables → Actions → New repository secret**:

| Secret | How to Get |
|--------|------------|
| `ARGOCD_SERVER` | Your ArgoCD server URL (e.g., `argocd.example.com`) |
| `ARGOCD_TOKEN` | Run: `argocd account generate-token --account YOUR_USERNAME` |

---

## Step 8: Test the Flow

### Test 1: PR → Plan

```bash
git checkout -b change-replicas
# edit k8s/deployment.yaml: change replicas: 2 → replicas: 3
git add .
git commit -m "Change replicas to 3"
git push origin change-replicas
```

Open a PR on GitHub → "Plan on PR" workflow runs → shows the changes.

### Test 2: Merge → Apply

Merge the PR. The "Apply on Merge" workflow triggers → calls ArgoCD sync.

### Test 3: Verify in cluster

```bash
kubectl get pods -n default
kubectl argo rollouts get deployment my-app -n default  # if using rollouts
```

---

## What You Practiced

| Practice | Skill |
|----------|-------|
| Writing K8s manifests | Deployment + Service structure |
| Kustomize | Bundling resources |
| GitHub Actions | `on: pull_request` vs `on: push` triggers |
| ArgoCD | Application CRD, auto-sync |
| Secrets | Secure CI/CD |
| Git flow | Feature branch → PR → merge |

---

## Commit Log Convention

```bash
git commit -m "[W9-D1] add: k8s manifests"
git commit -m "[W9-D1] add: GitHub Actions plan workflow"
git commit -m "[W9-D1] add: GitHub Actions apply workflow"
git commit -m "[W9-D1] add: ArgoCD Application manifest"
git commit -m "[W9-D1] test: verify plan on PR flow"
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| ArgoCD can't reach repo | Make repo public or add SSH key to ArgoCD |
| GitHub Actions can't reach ArgoCD | Check `ARGOCD_SERVER` and `ARGOCD_TOKEN` secrets |
| Sync stuck | `argocd app get my-app` to see errors |
| Workflow not triggering | Check workflow file is in `.github/workflows/` (correct folder name) |
