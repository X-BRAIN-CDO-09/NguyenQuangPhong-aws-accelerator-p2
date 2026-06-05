#!/bin/bash
set -e

if ! command -v socat &> /dev/null; then
  apt update && apt install -y socat
fi

if ! command -v docker &> /dev/null; then
  apt update && apt install -y docker.io
  systemctl enable docker && systemctl start docker
fi

if ! command -v minikube &> /dev/null; then
  curl -Lo /tmp/minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  install /tmp/minikube /usr/local/bin/minikube
fi

if ! command -v kubectl &> /dev/null; then
  curl -Lo /tmp/kubectl "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  install /tmp/kubectl /usr/local/bin/kubectl
fi

if ! minikube status &> /dev/null; then
  export HOME=/root
  minikube start --driver=docker --force --memory=2048mb --cpus=2
fi

# Create socat wrapper script (for systemd usage on boot)
cat > /usr/local/bin/socat-forward.sh << 'SCRIPT'
#!/bin/bash
IP=""
while [ -z "$IP" ]; do
  IP=$(/usr/local/bin/minikube ip 2>/dev/null | grep -E "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$")
  [ -z "$IP" ] && sleep 2
done
exec /usr/bin/socat TCP-LISTEN:30080,fork,reuseaddr TCP:$${IP}:30080
SCRIPT
chmod +x /usr/local/bin/socat-forward.sh

# Create systemd service for minikube (auto-start on boot)
cat > /etc/systemd/system/minikube.service << 'UNIT'
[Unit]
Description=Minikube Kubernetes cluster
After=docker.service
Wants=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/minikube start --driver=docker --force --memory=2048mb --cpus=2
ExecStop=/usr/local/bin/minikube stop
Environment=HOME=/root

[Install]
WantedBy=multi-user.target
UNIT

# Create systemd service for socat forward (auto-start on boot, restart on failure)
cat > /etc/systemd/system/socat-nodeport.service << UNIT
[Unit]
Description=Socat forward port 30080 to minikube NodePort
After=minikube.service docker.service network-online.target
Wants=minikube.service

[Service]
Type=simple
ExecStart=/usr/local/bin/socat-forward.sh
Restart=always
RestartSec=5
Environment=HOME=/root

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now minikube.service socat-nodeport.service

cat > /tmp/deployment.yaml << 'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: web
          image: nginx:alpine
          ports:
            - containerPort: 80
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 3
            periodSeconds: 5
YAML

cat > /tmp/service.yaml << 'YAML'
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  type: NodePort
  selector:
    app: my-app
  ports:
    - port: 80
      targetPort: 80
      nodePort: ${node_port}
YAML

kubectl apply -f /tmp/deployment.yaml
kubectl apply -f /tmp/service.yaml
