# Day B — Kustomize-only Observability Stack

## What you'll build

```
my-app (nginx + exporter sidecar) → /metrics
  ↑ scrape
Prometheus (stores metrics, evaluates alert rules)
  ↓ query
Grafana (dashboards + visualize)
```

All deployed with pure Kustomize — no Helm.

---

## Files to Create

```
1-kustomize-project/
├── practice.md          (this file)
├── my-app-metrics/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
├── prometheus/
│   ├── configmap.yaml       # prometheus.yml scrape config
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── alert-rules.yaml     # SLO burn rate rules
│   └── kustomization.yaml
└── grafana/
    ├── configmap.yaml       # Prometheus datasource config
    ├── deployment.yaml
    ├── service.yaml
    └── kustomization.yaml
```

---

## Step 1: App with Metrics Exporter

nginx doesn't expose `/metrics` natively. Add an **nginx-exporter sidecar** that scrapes nginx's status page and converts it to Prometheus metrics.

### my-app-metrics/deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 2
  selector:
    matchLabels: {}
  template:
    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9113"
    spec:
      containers:
        - name: nginx
          image: nginx:latest
          ports:
            - containerPort: 80
        - name: exporter
          image: nginx/nginx-prometheus-exporter:latest
          args:
            - -nginx.scrape-uri=http://localhost:80/status
          ports:
            - containerPort: 9113
              name: metrics
```

### my-app-metrics/service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9113"
spec:
  selector:
    app: my-app
  ports:
    - name: http
      port: 80
      targetPort: 80
    - name: metrics
      port: 9113
      targetPort: 9113
```

### my-app-metrics/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
commonLabels:
  app: my-app
```

---

## Step 2: Prometheus

Three resources: ConfigMap (scrape config + rules), Deployment, Service.

### prometheus/configmap.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    scrape_configs:
      - job_name: 'my-app'
        static_configs:
          - targets: ['my-app:9113']
    rule_files:
      - /etc/prometheus/rules/*.yaml
```

### prometheus/alert-rules.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-rules
data:
  slo-rules.yaml: |
    groups:
      - name: slo-alerts
        rules:
          - alert: HighErrorRate
            expr: |
              rate(nginx_http_requests_total{status=~"5.."}[5m])
                / rate(nginx_http_requests_total[5m]) > 0.01
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "Error rate > 1% for 5 minutes"

          - alert: BurnRateFast
            expr: |
              (1 - (
                rate(nginx_http_requests_total{status=~"2..|3.."}[1h])
                  / rate(nginx_http_requests_total[1h])
              )) > 0.001 * 14.4
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "Fast burn rate: SLO budget burning too fast"

          - alert: BurnRateSlow
            expr: |
              (1 - (
                rate(nginx_http_requests_total{status=~"2..|3.."}[6h])
                  / rate(nginx_http_requests_total[6h])
              )) > 0.001 * 6
            for: 30m
            labels:
              severity: warning
            annotations:
              summary: "Slow burn rate: SLO budget burning steadily"
```

### prometheus/deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
spec:
  replicas: 1
  selector:
    matchLabels: {}
  template:
    spec:
      containers:
        - name: prometheus
          image: prom/prometheus:latest
          args:
            - --config.file=/etc/prometheus/prometheus.yml
            - --storage.tsdb.path=/prometheus
          ports:
            - containerPort: 9090
          volumeMounts:
            - name: config
              mountPath: /etc/prometheus
            - name: rules
              mountPath: /etc/prometheus/rules
      volumes:
        - name: config
          configMap:
            name: prometheus-config
        - name: rules
          configMap:
            name: prometheus-rules
```

### prometheus/service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: prometheus
spec:
  selector:
    app: prometheus
  ports:
    - port: 9090
      targetPort: 9090
```

### prometheus/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml
  - alert-rules.yaml
commonLabels:
  app: prometheus
```

---

## Step 3: Grafana

### grafana/configmap.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-config
data:
  datasource.yaml: |
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        access: proxy
        url: http://prometheus:9090
        isDefault: true
```

### grafana/deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
spec:
  replicas: 1
  selector:
    matchLabels: {}
  template:
    spec:
      containers:
        - name: grafana
          image: grafana/grafana:latest
          ports:
            - containerPort: 3000
          env:
            - name: GF_AUTH_ANONYMOUS_ENABLED
              value: "true"
          volumeMounts:
            - name: config
              mountPath: /etc/grafana/provisioning/datasources
      volumes:
        - name: config
          configMap:
            name: grafana-config
```

### grafana/service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: grafana
spec:
  type: NodePort
  selector:
    app: grafana
  ports:
    - port: 3000
      targetPort: 3000
      nodePort: 30300
```

### grafana/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml
commonLabels:
  app: grafana
```

---

## Step 4: Apply

```bash
kubectl apply -k 1-kustomize-project/my-app-metrics
kubectl apply -k 1-kustomize-project/prometheus
kubectl apply -k 1-kustomize-project/grafana
kubectl get pods
```

---

## Step 5: Verify

```bash
# Check Prometheus targets page
kubectl port-forward svc/prometheus 9090:9090
# → http://localhost:9090/targets — my-app should be UP

# Check Grafana
minikube ip
# → http://<minikube-ip>:30300 (no login, anonymous enabled)

# Generate traffic to see metrics
kubectl port-forward svc/my-app 8080:80
curl -s http://localhost:8080
curl -s http://localhost:8080/nonexistent  # triggers error
```

---

## Key PromQL to Try in Grafana

```promql
# Request rate
rate(nginx_http_requests_total[5m])

# Error rate
rate(nginx_http_requests_total{status=~"5.."}[5m])

# Availability SLI
rate(nginx_http_requests_total{status=~"2..|3.."}[5m])
  / rate(nginx_http_requests_total[5m])

# Error budget burn rate (over 1h)
1 - (
  rate(nginx_http_requests_total{status=~"2..|3.."}[1h])
    / rate(nginx_http_requests_total[1h])
) / 0.001
```

---

## Clean Up

```bash
kubectl delete -k 1-kustomize-project/prometheus
kubectl delete -k 1-kustomize-project/grafana
kubectl delete -k 1-kustomize-project/my-app-metrics
```
