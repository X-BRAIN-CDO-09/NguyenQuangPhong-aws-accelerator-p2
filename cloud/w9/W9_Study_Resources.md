# Week 9 Study Resources - Deliver Smartly

## Day 1 (T2 08/06) - GitOps & CI/CD

### Core Topics
- GitHub Actions: plan-on-PR + apply-on-merge
- ArgoCD vs Flux
- App-of-apps pattern
- Sync waves
- Rollback: `git revert` vs `kubectl rollout undo`

### Official Documentation
- [ArgoCD Docs - Getting Started](https://argo-cd.readthedocs.io) → [App of Apps](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Flux Docs](https://fluxcd.io/flux) (alternative to ArgoCD)
- [GitOps Principles (OpenGitOps)](https://opengitops.dev)

### Repo Structure
```
cloud/w9/day-a/
  .github/workflows/
  argocd/
```

---

## Day 2 (T3 09/06) - Observability: SLO/SLI/OTel

### Core Topics
- OpenTelemetry: SDK + Collector
- Prometheus + Grafana + Loki stack
- SLO Methodology: availability + latency
- Multi-window burn rate alerts:
  - Fast: 1h × 5min
  - Slow: 6h × 30min

### Official Documentation
- [OpenTelemetry Docs](https://opentelemetry.io/docs) → Concepts → Instrumentation
- [Prometheus Docs](https://prometheus.io/docs)
- [Grafana Docs](https://grafana.com/docs/grafana/latest)
- [Loki Docs](https://grafana.com/docs/loki/latest)

### SRE Resources (Google)
- [SLO Chapter - SRE Book](https://sre.google/sre-book/service-level-objectives)
- [Implementing SLOs - Workbook](https://sre.google/workbook/implementing-slos)
- [Multi-window Burn Rate Alerting](https://sre.google/workbook/alerting-on-slos)

### Repo Structure
```
cloud/w9/day-b/
  otel/
  dashboards/
  alert-rules/
```

---

## Day 3 (T4 10/06) - Progressive Delivery (Canary) *Preview*

### Core Topics
- Argo Rollouts & Rollout CRD
- AnalysisTemplate with Prometheus queries
- Abort criteria
- Integration with burn rate alerts

### Documentation
- [Argo Rollouts Docs](https://argoproj.github.io/argo-rollouts) → Concepts → Analysis
- [Flagger Docs](https://flagger.app) (alternative)
- [Progressive Delivery Patterns - CNCF](https://www.cncf.io/blog/2024/01/26/progressive-delivery/)

### Repo Structure
```
cloud/w9/day-c/
  rollout/
  analysis-template/
```

---

## Lab (T5-T6 11-12/06) - Onsite Đà Nẵng

### Goal
GitOps-ify W8 platform + bolt-on observability + canary

### Repo Structure
```
cloud/w9/lab/
```

### Load Testing Tools
- [k6 Docs](https://k6.io/docs) (recommended for CI)
- [Vegeta](https://github.com/tsenart/vegeta) (CLI alternative)

---

## Commit Convention
```
[W9-D1] <short-topic>
[W9-D2] <short-topic>
[W9-D3] <short-topic>
[W9-LAB] <short-topic>
```

Push daily T2–T4.

---

## Support Channels
- Questions: `#phase2-cloud-daily`
- Technical help: `#phase2-cloud-help` (with screenshot + log)
- Urgent: DM mentor Minh

---

## Live Session
**T4 10/06 15h–17h**: Monitoring/Observability with mentor Minh (online)
**T4 17h–18h**: Online Test 1 (D1 + D2 scope)
**T6 15h–16h**: Online Test 2 (D3 + Lab scope)