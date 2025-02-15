#!/bin/bash

set -e  # Exit on any error

# =======================
# 2. Load .env Values
# =======================
if [ -f ".env" ]; then
  echo "Loading environment variables from .env..."
  export $(grep -v '^#' .env | xargs)
else
  echo ".env file not found. Please provide it."
  exit 1
fi

echo "Starting Kubernetes deployment for PersonaBrief..."

# =======================
# 1. Kubeconfig Setup
# =======================
echo "Removing existing kubeconfig entry..."
rm -f ~/.kube/config

echo "Generating cluster config for $CLUSTER_NAME in $ZONE under $PROJECT_ID..."
gcloud container clusters get-credentials "$CLUSTER_NAME" \
  --zone "$ZONE" \
  --project "$PROJECT_ID"

echo "Setting namespace context to $NAMESPACE..."
kubectl config set-context --current --namespace "$NAMESPACE"

# =======================
# 3. Helm Values Injection
# =======================
echo "Injecting environment variables into values.yaml..."
envsubst < values.template.yaml > app_chart/values.yaml

# =======================
# 4. Cilium Installation
# =======================
echo "Installing Cilium CLI..."
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all \
  https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvf cilium-linux-${CLI_ARCH}.tar.gz -C /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

echo "Enabling Hubble UI..."
cilium hubble enable --ui

echo "installing prometheus and grafana"
kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/1.17.1/examples/kubernetes/addons/prometheus/monitoring-example.yaml

# =======================
# 5. Helm Chart Deployment
# =======================
echo "Installing PersonaBrief Helm chart..."
helm upgrade --install persona-brief ./app_chart \
  --values app_chart/values.yaml


# =======================
# 7. Pixie Installation
# =======================
echo "Installing Pixie..."
bash -c "$(curl -fsSL https://work.withpixie.ai/install.sh)"

PIXIE_BIN="$HOME/bin"
if [ -d "$PIXIE_BIN" ]; then
  echo "Adding Pixie to PATH..."
  sudo cp "$PIXIE_BIN/px" /usr/local/bin/px
else
  echo "Pixie binary not found in $PIXIE_BIN"
  exit 1
fi

# Verify Pixie installation
if command -v px &> /dev/null; then
  echo "Pixie installed successfully"
else
  echo "Failed to install Pixie"
  exit 1
fi

echo "Deploying Pixie to Kubernetes..."
px auth login
px deploy

echo "PersonaBrief deployment completed successfully! 🚀"
