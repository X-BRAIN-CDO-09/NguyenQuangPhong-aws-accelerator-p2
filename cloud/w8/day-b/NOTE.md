# [W8-D2] Docker & Kubernetes Fundamentals

---

## 1. Docker Architecture

```
dockerd            ── REST API, build, network, volume (high level)
   │ gRPC
   ▼
containerd         ── pull images, manage storage, container lifecycle
   │
   ▼
containerd-shim    ── stays behind to watch the container
   │ calls runc
   ▼
runc               ── creates namespaces + cgroups, then EXITS (OCI)
   │
   ▼
[ process inside the container ]
```

- **dockerd**: High-level daemon. User interacts with this via `docker` CLI.
- **containerd**: Industry-standard container runtime. Pulls images, manages lifecycle.
- **containerd-shim**: Stays alive after container starts. Keeps container running even if dockerd restarts.
- **runc**: OCI runtime. Creates namespaces + cgroups, spawns the process, then exits.

---

## 2. Container Isolation (Linux Kernel Features)

An ordinary process becomes a "container" when wrapped with:

### Namespaces — What the process sees

| Namespace | Isolates |
| :--- | :--- |
| PID | Process IDs — container only sees its own processes |
| Network | Network interfaces, routing, iptables |
| Mount | Filesystem mount points |
| UTS | Hostname and domain name |
| IPC | Inter-process communication (shared memory, semaphores) |
| User | User and group IDs |

Check namespaces from inside a container:
```bash
docker run --rm alpine ls -l /proc/self/ns/
```

### Cgroups — How much it can use

Control Groups limit CPU, memory, disk I/O for a group of processes.

```bash
# Limit container to 50MB RAM
docker run --rm --memory=50m alpine cat /sys/fs/cgroup/memory.max
# => 52428800 (50 × 1024 × 1024)
```

Other limits: `--cpus` (CPU cores), `--cpu-shares` (relative weight).

### Union Filesystem — Which filesystem it sees

Multiple read-only layers (from image) + one writable layer (container) merged into a single filesystem via union mount.

```
Writable layer (container's own changes)
──────────────────────────────────────
Layer 4: CMD, ENV (metadata)
Layer 3: COPY code
Layer 2: RUN npm install
Layer 1: base OS (alpine, ubuntu)
     └── union mount → process sees 1 seamless tree
```

**Copy-on-Write:** When a process modifies a file from a read-only layer, the file is copied to the writable layer first, then modified.

---

## 3. Dockerfile Instructions

| Instruction | When | What it does |
| :--- | :--- | :--- |
| `FROM` | Build | Base image |
| `WORKDIR` | Build | Set working directory |
| `COPY` | Build | Copy files from host to image |
| `RUN` | Build | Execute command (creates a new layer) |
| `EXPOSE` | Build | Document port (documentation only) |
| `CMD` | Runtime | Default command when container starts |

### Build Cache Optimization

Docker caches each layer. On rebuild, only layers after the first change are rebuilt.

```dockerfile
FROM node:20-alpine     ← CACHED (base image)
WORKDIR /app            ← CACHED
COPY package.json ./    ← CACHED (if package.json unchanged)
RUN npm install         ← CACHED (because input unchanged)
COPY . .                ← REBUILD (code changed)
CMD ["npm", "start"]    ← REBUILD
```

**Pattern:** Copy dependency manifest (`package.json`) before code → `RUN npm install` is cached on code changes.

---

## 4. Kubernetes Core Concepts

### Pod

Smallest deployable unit in K8s. Wraps one or more containers sharing:
- Network namespace (same IP, localhost communication)
- Storage volumes
- Lifecycle

### Service

Provides a stable IP and DNS name for a set of pods (selected by labels). Types:

| Type | Accessible from | Use case |
| :--- | :--- | :--- |
| **ClusterIP** (default) | Inside cluster only | Internal services (APIs, databases) |
| **NodePort** | Outside cluster via `<NodeIP>:<NodePort>` | Development, direct access |
| **LoadBalancer** | External via cloud LB | Production, public-facing apps |

### ConfigMap & Secret

Both inject configuration into pods, but:

| | ConfigMap | Secret |
| :--- | :--- | :--- |
| Data format | Plain text | Base64-encoded |
| Intended for | Non-sensitive config (env, ports, URLs) | Sensitive data (passwords, tokens, keys) |
| Envelope encryption | No | Optional (KMS) |
| Manifest readability | Readable | Obfuscated |

Both can be injected via:
- **`envFrom`**: All key-value pairs become environment variables
- **Volume mount**: Each key becomes a file in a directory

### Probes (Health Checks)

| Probe | What it checks | If fails |
| :--- | :--- | :--- |
| **livenessProbe** | Is the container alive? | K8s restarts the container |
| **readinessProbe** | Is the container ready to serve traffic? | K8s removes it from Service endpoints |
| **startupProbe** | Has the app finished starting? | Delays liveness/readiness checks |

Types of probe handlers: `httpGet` (HTTP GET), `tcpSocket` (TCP connect), `exec` (run command in container).

### NetworkPolicy

Firewall for pods. By default, all pods can communicate freely. NetworkPolicy defines ingress/egress rules based on:
- `podSelector` (target pods)
- `from`/`to` (source/destination: podSelector, namespaceSelector, ipBlock)
- `ports` (allowed ports)

**Principle of least privilege:** Only allow traffic that is explicitly required.

---

## 5. Key kubectl Commands

| Command | What it does |
| :--- | :--- |
| `kubectl get all` | List all resources in namespace |
| `kubectl get pods -o wide` | List pods with node IP info |
| `kubectl describe pod <name>` | Detailed pod info (events, status) |
| `kubectl logs <name>` | Show container logs |
| `kubectl logs -f <name>` | Stream logs (tail -f equivalent) |
| `kubectl exec -it <name> -- sh` | Shell into container |
| `kubectl port-forward pod/<name> 3000:3000` | Forward local port to pod |
| `kubectl scale deployment <name> --replicas=5` | Scale replicas up/down |
| `kubectl apply -f <file>` | Create/update resource from YAML |
| `kubectl delete -f <file>` | Delete resource from YAML |

---

## 6. End-to-End Flow

```
1. docker build             →  Image
2. eval $(minikube docker-env)  →  Point Docker to minikube's daemon
3. docker build             →  Image available inside minikube
4. kubectl apply -f configmap.yaml
5. kubectl apply -f secret.yaml
6. kubectl apply -f deployment.yaml   (image: my-express-app, imagePullPolicy: Never)
7. kubectl apply -f service.yaml      (NodePort)
8. kubectl apply -f network-policy.yaml
9. minikube service my-web-service --url  →  Access the app
```

---

## 7. Why Companies Do This

| Practice | Why |
| :--- | :--- |
| **Docker** | Consistent environment from dev to production. "It works on my machine" no more. |
| **Kubernetes** | Self-healing (restart on crash), scaling (up/down on demand), rolling updates (zero-downtime deploy). |
| **ConfigMap + Secret** | 12-Factor App: config externalized from code. Secrets encrypted and not committed. |
| **Probes** | Automatic recovery from failures. Zero-downtime during rolling updates (readiness). |
| **NetworkPolicy** | Security isolation. In production, you don't want your database accessible from the internet. |
| **Minikube** | Local dev cluster that mirrors production behavior without cloud cost. |
