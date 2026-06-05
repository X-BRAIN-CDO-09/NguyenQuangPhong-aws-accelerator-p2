# Day B — Step-by-Step (Docker + Kubernetes)

---

## Cấu trúc

```
day-b/
  docker.md                # Docker commands reference
  dockerImage.md           # Docker image + build cache theory
  note-original.md         # Raw notes
  dockerfile-practice/
    Dockerfile             # Express app Dockerfile
    package.json
    server.js
  k8s-practice/
    configmap.yaml         # ConfigMap with env vars
    secret.yaml            # Secret with sensitive data
    deployment.yaml        # Deployment with probes + envFrom
    service.yaml           # NodePort Service
    network-policy.yaml    # NetworkPolicy to restrict traffic
    run.md                 # Commands to run in order
  guide.md                 # Step-by-step instruction
  NOTE.md                  # Polished theory
```

---

## Bước 1: Docker — Build image và chạy thử

```bash
cd cloud/w8/day-b/dockerfile-practice

# Build image từ Dockerfile
docker build -t my-express-app:v1 .

# Chạy container để test
docker run --rm -d -p 3000:3000 --name express-demo my-express-app:v1

# Kiểm tra
curl http://localhost:3000
# => "Hello from container"

# Xem logs
docker logs express-demo

# Dọn dẹp
docker rm -f express-demo
```

**Giải thích build cache:**
```
FROM node:20-alpine    ← cached
WORKDIR /app           ← cached
COPY package.json ./   ← cached (nếu package.json không đổi)
RUN npm install        ← cached (vì layer trước cached)
COPY . .               ← rebuild nếu code thay đổi
CMD [ "npm", "start" ] ← rebuild
```
Copy `package.json` trước `RUN npm install` → code thay đổi không reinstall dependencies.

---

## Bước 2: Cho phép minikube dùng image vừa build

Minikube có Docker daemon riêng bên trong container. Image build trên host không tự động available trong minikube.

```bash
# Trỏ Docker CLI vào Docker daemon của minikube
eval $(minikube docker-env)

# Build lại image trong minikube's Docker
cd cloud/w8/day-b/dockerfile-practice
docker build -t my-express-app:v1 .
```

**Why?** `minikube docker-env` export các biến môi trường để `docker` command trên host nói chuyện với Docker daemon bên trong minikube container. Image build lúc này sẽ nằm trong minikube, K8s có thể pull được.

---

## Bước 3: Tạo ConfigMap + Secret

### File `k8s-practice/configmap.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-settings
data:
  APP_ENV: "development"
  LOG_LEVEL: "debug"
```

### File `k8s-practice/secret.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
stringData:
  DB_PASSWORD: "supersecret123"
  API_KEY: "sk-abc123"
```

**So sánh ConfigMap vs Secret:**

| | ConfigMap | Secret |
| :--- | :--- | :--- |
| Dữ liệu | Plain text | Base64 encoded (khi apply, nhập plain text với `stringData`) |
| Dùng cho | Config không nhạy cảm | Password, token, key |
| Inject vào pod | `envFrom` hoặc volume | `envFrom` hoặc volume |
| Security | Không có | Có thể encryption at-rest (nếu cấu hình) |

Apply:
```bash
kubectl apply -f k8s-practice/configmap.yaml
kubectl apply -f k8s-practice/secret.yaml
```

---

## Bước 4: Tạo Deployment

### File `k8s-practice/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: express-app
          image: my-express-app:v1
          imagePullPolicy: Never
          ports:
            - containerPort: 3000
          envFrom:
            - configMapRef:
                name: app-settings
            - secretRef:
                name: app-secrets
          livenessProbe:
            httpGet:
              path: /
              port: 3000
            initialDelaySeconds: 5
          readinessProbe:
            httpGet:
              path: /
              port: 3000
            initialDelaySeconds: 3
```

**Khác với bản cũ (dùng nginx):**

| Thay đổi | Cũ | Mới |
| :--- | :--- | :--- |
| Image | `nginx:alpine` | `my-express-app:v1` (image tự build) |
| `imagePullPolicy` | Không có (mặc định) | `Never` (không pull từ registry, dùng image local trong minikube) |
| Port | 80 | 3000 (Express app port) |
| `envFrom` | Chỉ ConfigMap | ConfigMap + Secret |
| Probe path | `/` trên port 80 | `/` trên port 3000 |

**`imagePullPolicy: Never` là gì?** Bình thường K8s thử pull image từ registry (Docker Hub). Vì image của bạn chỉ có trong minikube local, không có trên Docker Hub → set `Never` để K8s dùng image local.

Apply:
```bash
kubectl apply -f k8s-practice/deployment.yaml
```

Kiểm tra:
```bash
kubectl get pods
kubectl get deployment
```

---

## Bước 5: Tạo Service

### File `k8s-practice/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-web-service
spec:
  selector:
    app: web
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
  type: NodePort
```

**Lưu ý:** `port: 80` (service port, cổng bên ngoài), `targetPort: 3000` (container port — Express app listens on 3000).

Apply:
```bash
kubectl apply -f k8s-practice/service.yaml
```

Kiểm tra:
```bash
kubectl get service
minikube service my-web-service --url
# Mở URL trong browser → thấy "Hello from container"
```

---

## Bước 6: Tạo NetworkPolicy

### File `k8s-practice/network-policy.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-only
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: web
      ports:
        - port: 3000
```

**NetworkPolicy làm gì?** Giới hạn traffic — chỉ pod có label `app: web` mới được gửi request đến port 3000 của pod khác cũng có label `app: web`. Các pod khác (không có label này) sẽ bị chặn.

**Why dùng NetworkPolicy?** Zero-trust security: mặc định K8s cho phép tất cả pods giao tiếp. Trong production, bạn muốn "allow by default deny" — chỉ cho phép traffic cần thiết.

Apply:
```bash
kubectl apply -f k8s-practice/network-policy.yaml
```

---

## Bước 7: Thực hành kubectl commands

```bash
# Xem tất cả resources
kubectl get all

# Xem pods chi tiết
kubectl get pods -o wide
kubectl describe pod <pod-name>

# Xem logs
kubectl logs <pod-name>
kubectl logs -f <pod-name>    # follow mode (giống tail -f)

# Exec vào container
kubectl exec -it <pod-name> -- sh
# Trong container: env  (xem biến môi trường từ ConfigMap + Secret)
# Trong container: curl localhost:3000  (test app bên trong)
# Exit: exit

# Port forward (truy cập pod trực tiếp không qua Service)
kubectl port-forward pod/<pod-name> 3000:3000
# Mở browser: http://localhost:3000

# Xem ConfigMap và Secret
kubectl get configmap app-settings -o yaml
kubectl get secret app-secrets -o yaml

# Scale deployment
kubectl scale deployment my-web-app --replicas=5
kubectl get pods  # thấy 5 pods

# Xem events
kubectl get events --sort-by='.lastTimestamp'
```

---

## Bước 8: Dọn dẹp

```bash
# Xóa K8s resources
kubectl delete -f k8s-practice/network-policy.yaml
kubectl delete -f k8s-practice/service.yaml
kubectl delete -f k8s-practice/deployment.yaml
kubectl delete -f k8s-practice/secret.yaml
kubectl delete -f k8s-practice/configmap.yaml

# Hoặc xóa tất cả cùng lúc
kubectl delete -f k8s-practice/

# Stop minikube (khi không dùng nữa)
minikube stop
```

---

## Tổng quan luồng

```
Dockerfile         ── docker build ──► Image (my-express-app:v1)
                                              │
                                    eval $(minikube docker-env)
                                              │
                                    build lại trong minikube's Docker
                                              │
                                    K8s Deployment dùng image đó
                                              │
                                    ConfigMap + Secret inject env vars
                                              │
                                    Service expose qua NodePort
                                              │
                                    NetworkPolicy restrict traffic
                                              │
                                    kubectl get/describe/logs/exec
```

---

## Tại sao công ty làm vậy?

| Practice | Why |
| :--- | :--- |
| **Docker → K8s cùng image** | Đảm bảo image chạy local giống hệt image trên K8s — "build once, run anywhere" |
| **ConfigMap + Secret** | 12-Factor App: config tách khỏi code. Secret có encryption, không commit vào Git |
| **Liveness + Readiness probe** | Tự động restart khi app crash, không gửi traffic vào pod đang không sẵn sàng |
| **NetworkPolicy** | Principle of least privilege — chỉ cho phép traffic cần thiết |
| **imagePullPolicy: Never** | K8s không cần registry, phù hợp dev local. Production dùng `Always` + registry |
| **kubectl exec** | Debug production mà không cần SSH vào node |
