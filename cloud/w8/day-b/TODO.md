# [W8-D2] Kubernetes Study - TODO

## 🔴 Status: In Progress
Docker fundamentals and image building are completed. Need to transition to Kubernetes (K8s) core concepts.

## 📝 Remaining Tasks

### 1. K8s Core Objects (Theoretical Study)
- [ ] **Pods:** Lifecycle and basic deployment.
- [ ] **Services:** Networking types (ClusterIP, NodePort, LoadBalancer).
- [ ] **Probes:** Implementing `livenessProbe` and `readinessProbe` for health checks.
- [ ] **ConfigMaps & Secrets:** Injecting configuration and sensitive data into pods.
- [ ] **NetworkPolicy:** Basic traffic control rules.

### 2. Practical Exercises (Local Cluster)
- [ ] Start `minikube` cluster.
- [ ] Create a `Deployment` manifest for the `dockerfile-practice` image.
- [ ] Expose the deployment using a `Service`.
- [ ] Verify pod health using `kubectl get pods`, `kubectl describe`, and `kubectl logs`.

### 3. Deliverables
- [ ] Create `k8s-practice/` directory.
- [ ] Add YAML manifests for Deployment and Service.
- [ ] Commit with prefix `[W8-D2] K8s basic objects and manifests`.

---
*Reference: [W8 Phase 2 Announcement](https://github.com/TechX-Corp/xbrain-learners/blob/main/W8/W8_phase2_announcement_cloud.md)*

## 📚 Reference Materials
- **Currently Reading:** [Docker Volumes & Bind Mounts](https://kkloudtarus.net/en/blog/volumes-and-bind-mounts-storing-data-persistently) (kkloudtarus.net)
- **Official K8s Tutorial:** [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- **Mentor Series (Docker):** [Docker from Basics to Swarm](https://kkloudtarus.net/en/blog/series/docker-from-basics-to-swarm) (Nghĩa Huỳnh)
- **Mentor Series (K8s):** [K8s from Basics to Production](https://kkloudtarus.net/en/blog/series/kubernetes-from-basics-to-advanced)
