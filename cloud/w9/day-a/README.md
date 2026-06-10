# [W9-D1] GitOps & CI/CD Fundamentals

## Overview
Today's focus is on transitioning from manual "click-to-deploy" or "terminal-to-deploy" to **GitOps**. The Git repository becomes the "Single Source of Truth" for your infrastructure and application state.

## Learning Objectives
1. **GitOps Principles**: Declarative, Versioned, Pulled automatically.
2. **GitHub Actions**: Implement automation for `plan-on-PR` and `apply-on-merge`.
3. **ArgoCD/Flux**: Research pull-based synchronization tools.
4. **App-of-Apps Pattern**: Manage multiple applications through a single "Root" app.

## Project Structure
- `.github/workflows/`: CI/CD logic for Terraform and K8s.
- `argocd/`: Manifests for ArgoCD Application resources.
- `k8s/`: Your application manifests (Single Source of Truth).

## References
- [ArgoCD Documentation](https://argo-cd.readthedocs.io)
- [OpenGitOps Principles](https://opengitops.dev)
- [GitHub Actions Guide](https://docs.github.com/en/actions)
