# Day B — Helm-only Observability Stack

## What you'll build

Same stack as the Kustomize project, but installed with **Helm** — one command instead of writing 10+ YAML files.

```
kube-prometheus-stack (Helm chart)
├── Prometheus
├── Grafana
├── Alertmanager
├── ServiceMonitors (auto-discovers pods)
└── Pre-built dashboards + alert rules
```

---

## Step 1: Add Helm Repo

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

---

## Step 2: Install the Stack

```bash
helm install observability prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

This single command deploys:
- Prometheus server + Operator
- Grafana (with built-in K8s dashboards)
- Alertmanager
- ServiceMonitors, PodMonitors
- Default alert rules

---

## Step 3: Verify

```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

Expected output:
```
NAME                                                   READY
alertmanager-observability-kube-prometheus-alertmanager   2/2
observability-grafana                                     1/1
observability-kube-prometheus-operator                    1/1
observability-kube-state-metrics                          1/1
observability-prometheus-node-exporter                    1/1
prometheus-observability-kube-prometheus-prometheus       2/2
```

---

## Step 4: Open Grafana

```bash
# Port-forward
kubectl port-forward svc/observability-grafana 3000:80 -n monitoring

# Login: admin / prom-operator (default)
# Or get the password:
kubectl get secret observability-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 -d
```

Grafana comes with pre-installed dashboards:
- Kubernetes cluster overview
- Node metrics
- Pod metrics
- etc.

---

## Step 5: Annotate Your App for Auto-discovery

Prometheus Operator auto-discovers pods with these annotations:

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9113"
```

If your my-app (from the Kustomize project) is running, the Helm-installed Prometheus will automatically find it.

---

## Step 6: Customize with values.yaml (The Helm Way)

Create `my-values.yaml` to override defaults:

```yaml
grafana:
  adminPassword: mypassword
  service:
    type: NodePort
    nodePort: 30300
  env:
    GF_AUTH_ANONYMOUS_ENABLED: "true"

prometheus:
  prometheusSpec:
    ruleSelectorNilUsesHelmValues: false
    ruleNamespaceSelector: {}
    additionalAlertManagerConfigs:
      - scheme: http
        path_prefix: /
        static_configs:
          - targets: ["alertmanager:9093"]
```

Upgrade the release:

```bash
helm upgrade observability prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f my-values.yaml
```

---

## Key Difference from Kustomize

| Aspect | Kustomize (project 1) | Helm (this project) |
|--------|----------------------|---------------------|
| **Setup time** | Write 10+ files | 2 commands |
| **Customization** | Full YAML control | values.yaml (limited to what chart exposes) |
| **Grafana dashboards** | None (build yourself) | Pre-built K8s dashboards |
| **Alert rules** | Write your own | Built-in K8s alerts |
| **Service discovery** | Static targets | Auto via ServiceMonitor |
| **Learning** | You understand every component | You understand the chart interface |

---

## Clean Up

```bash
helm uninstall observability -n monitoring
kubectl delete namespace monitoring
```
