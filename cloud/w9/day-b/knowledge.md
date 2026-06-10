# Day B Knowledge: Observability — SLO/SLI/OTel

---

## 1. Three Pillars of Observability

| Pillar | What | Tool |
|--------|------|------|
| **Metrics** | Numbers over time (CPU, latency, error rate) | Prometheus |
| **Logs** | Event records with timestamps | Loki |
| **Traces** | Request lifecycle across services | OpenTelemetry |

---

## 2. OpenTelemetry (OTel)

### What it is
A vendor-neutral standard for collecting telemetry data (metrics, logs, traces).

### Architecture

```
Your App → OTel SDK → OTel Collector → Prometheus/Grafana/Loki
```

| Component | Role |
|-----------|------|
| **OTel SDK** | Instrument your app (auto or manual) |
| **OTel Collector** | Receives, processes, and exports telemetry |
| **OTel Exporter** | Sends data to backend (Prometheus, Jaeger, etc.) |

### Common pipeline

```
App (with OTel SDK)
  → OTel Collector (runs as deployment in cluster)
    → Prometheus (metrics)
    → Loki (logs)
    → Jaeger (traces)
```

---

## 3. Prometheus

### What it is
A time-series database for metrics + alerting.

### How it works

```
Prometheus scrapes metrics from targets (pods/services)
  → Stores in TSDB
  → Evaluates alerting rules
  → Triggers Alertmanager
```

### Key concepts

| Concept | Meaning |
|---------|---------|
| **Target** | Endpoint to scrape (e.g., `my-app:80/metrics`) |
| **Metric** | Time-series data point (`http_requests_total{method="GET", status="200"}`) |
| **Labels** | Key-value pairs to identify metrics dimensions |
| **PromQL** | Query language to aggregate/filter metrics |
| **Recording rules** | Pre-compute expensive queries |
| **Alerting rules** | Define conditions for alerts |

### Common metric types

| Type | Example | Use |
|------|---------|-----|
| Counter | `http_requests_total` | Cumulative count |
| Gauge | `memory_usage_bytes` | Up/down value |
| Histogram | `request_duration_seconds` | Distribution (p50, p99) |
| Summary | Same as histogram | Pre-computed quantiles |

---

## 4. Grafana

### What it is
Dashboard UI for metrics (Prometheus, Loki, etc.).

### Key concepts

| Concept | Meaning |
|---------|---------|
| **Data source** | Where metrics come from (Prometheus, Loki) |
| **Dashboard** | A page with panels |
| **Panel** | A single chart/table |
| **Query** | PromQL or LogQL to fetch data for panel |
| **Alert** | Notification rule from panel |

---

## 5. Loki

### What it is
Log aggregation system (like Prometheus but for logs).

```
Loki pulls logs from pods
  → Indexes labels (not content)
  → Queryable via LogQL
```

### Key difference from Elasticsearch

| Loki | Elasticsearch |
|------|---------------|
| Only indexes labels (cheap) | Indexes full content (expensive) |
| Works with Prometheus labels | Requires separate schema |
| Grafana native | Kibana |

---

## 6. SLO / SLI / SLA

### Definitions

| Term | Meaning | Example |
|------|---------|---------|
| **SLI** (Service Level Indicator) | What you measure | Request latency p99 |
| **SLO** (Service Level Objective) | Target value | p99 latency < 200ms over 30 days |
| **SLA** (Service Level Agreement) | Contract with customer | < 200ms p99, 99.9% uptime |

### SLI types (Google SRE book)

| SLI | Metric |
|-----|--------|
| Availability | Good requests / Total requests |
| Latency | % of requests under threshold |
| Throughput | Requests per second |
| Errors | % of failed requests |

### Common formula

```
Availability SLI = count(status_code = 2xx or 3xx) / count(all requests)
```

---

## 7. Burn Rate Alerts

### What is a burn rate
How fast you're consuming your error budget.

```
Error budget = (1 - SLO) × time window
Example: 99.9% SLO → 0.1% error budget over 30 days = 43.2 minutes
```

### Multi-window burn rate approach

| Window | Duration | Severity | When to alert |
|--------|----------|----------|---------------|
| **Fast** | 1h × 5min resolution | Critical (page) | SLO burn rate > 14.4× in 1h |
| **Slow** | 6h × 30min resolution | Warning (ticket) | SLO burn rate > 6× in 6h |

### Why two windows

| Window | Catches |
|--------|---------|
| Fast (1h) | Sudden outage |
| Slow (6h) | Gradual degradation |

---

## 8. Full Day-B Stack in Cluster

```
my-app (instrumented with OTel SDK)
  ↓
OTel Collector (Deployment in cluster)
  ↓
Prometheus (metrics)     Loki (logs)
  ↓                         ↓
Grafana (dashboards + alerts)
  ↓
Alertmanager → Slack/PagerDuty
```

### Repo structure

```
cloud/w9/day-b/
├── otel/
│   ├── collector.yaml        # OTel Collector config
│   └── deployment.yaml       # Collector deployment
├── prometheus/
│   ├── prometheus.yaml       # Scrape config + rules
│   └── alert-rules.yaml      # Alerting rules
├── dashboards/
│   └── slo-dashboard.json    # Grafana dashboard (JSON)
└── knowledge.md
```

---

## References

- [OpenTelemetry Docs](https://opentelemetry.io/docs) — Concepts → Instrumentation
- [Prometheus Docs](https://prometheus.io/docs) — Querying → PromQL
- [Grafana Docs](https://grafana.com/docs/grafana/latest) — Dashboards → Panels
- [Loki Docs](https://grafana.com/docs/loki/latest) — LogQL
- [Google SRE Book — SLOs](https://sre.google/sre-book/service-level-objectives)
- [Multi-window Burn Rate Alerting](https://sre.google/workbook/alerting-on-slos)
