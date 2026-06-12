# Day B — Combined Kustomize + Helm

## The Production Pattern

```
Helm installs the heavy stack (kube-prometheus-stack)
  → Prometheus, Grafana, Alertmanager, ServiceMonitors
  ↓
Kustomize adds your custom stuff
  → Custom dashboards, SLO alert rules, team-specific configs
```

This is what real teams do: **Helm for the standard stuff, Kustomize for the custom stuff**.

---

## Two Approaches

### Approach A: Helm installs + Kustomize patches

```bash
# 1. Helm installs the base stack
helm install observability prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace

# 2. Kustomize adds your custom overlays on top
kubectl apply -k overlays/custom-dashboards/
kubectl apply -k overlays/slo-alerts/
```

Your `overlays/custom-dashboards/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

configMapGenerator:
  - name: grafana-dashboard-slo
    files:
      - slo-dashboard.json
    options:
      labels:
        grafana_dashboard: "1"
```

> Grafana auto-discovers ConfigMaps with label `grafana_dashboard: "1"` — so your custom dashboard appears automatically.

### Approach B: Kustomize wraps Helm (helmCharts)

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

helmCharts:
  - name: kube-prometheus-stack
    repo: https://prometheus-community.github.io/helm-charts
    version: 60.0.0
    releaseName: observability
    namespace: monitoring
    valuesFile: values.yaml
    includeCRDs: true

patches:
  - patch: |-
      - op: replace
        path: /spec/replicas
        value: 2
    target:
      kind: Prometheus
      name: observability-kube-prometheus-prometheus
```

**Apply with just kubectl** (no Helm CLI needed):

```bash
kubectl apply -k .
```

---

## Project Structure

```
3-combined-project/
├── practice.md                (this file)
├── overlays/
│   ├── custom-dashboards/
│   │   ├── kustomization.yaml
│   │   └── slo-dashboard.json
│   └── slo-alerts/
│       ├── kustomization.yaml
│       └── slo-rules.yaml
├── values.yaml                # Custom Helm values
├── kustomization.yaml         # Approach B: helmCharts (optional)
```

---

## values.yaml

```yaml
grafana:
  adminPassword: admin123
  service:
    type: NodePort
    nodePort: 30300
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
        - name: custom
          orgId: 1
          folder: custom
          type: file
          disableDeletion: true
          editable: true
          options:
            path: /var/lib/grafana/dashboards/custom
  dashboardsConfigMaps:
    custom: grafana-dashboard-slo

prometheus:
  prometheusSpec:
    ruleSelectorNilUsesHelmValues: false
    ruleNamespaceSelector: {}
```

---

## SLO Dashboard JSON Example

Save as `overlays/custom-dashboards/slo-dashboard.json`:

```json
{
  "title": "SLO Dashboard",
  "panels": [
    {
      "title": "Error Budget",
      "type": "graph",
      "targets": [
        {
          "expr": "rate(nginx_http_requests_total{status=~\"5..\"}[5m]) / rate(nginx_http_requests_total[5m]) * 100",
          "legendFormat": "Error %"
        }
      ]
    },
    {
      "title": "Request Rate",
      "type": "graph",
      "targets": [
        {
          "expr": "rate(nginx_http_requests_total[5m])",
          "legendFormat": "Requests/s"
        }
      ]
    }
  ]
}
```

---

## Applying the Combined Setup

### With Approach A:

```bash
# 1. Install base with Helm
helm install observability prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  -f 3-combined-project/values.yaml

# 2. Apply custom overlays with Kustomize
kubectl apply -k 3-combined-project/overlays/custom-dashboards/
kubectl apply -k 3-combined-project/overlays/slo-alerts/
```

### With Approach B:

```bash
# Single command — no Helm CLI needed
kubectl apply -k 3-combined-project/
```

---

## What You Learned

| Skill | Why it matters |
|-------|---------------|
| Helm for base install | Fast, standard, community-maintained |
| Kustomize overlays | Team-specific customizations Helm can't express |
| Grafana dashboard provisioning | ConfigMaps auto-discovered by label |
| Prometheus rule injection | Custom SLO alerts alongside built-in rules |
| helmCharts in Kustomize | No Helm CLI dependency for deployment |

---

## When to Use Which

| Scenario | Approach |
|----------|----------|
| Quick POC | Helm only (project 2) |
| Learning components | Kustomize only (project 1) |
| Production team | Combined (this project) |
| Single apply for everything | Approach B (helmCharts in Kustomize) |

---

## Clean Up

```bash
helm uninstall observability -n monitoring
kubectl delete namespace monitoring
```
