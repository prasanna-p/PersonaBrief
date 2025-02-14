#!/bin/bash

set -e  # Exit on any error

echo "Applying Kubernetes resources for PersonaBrief..."

# Remove existing kubeconfig
echo "Removing kubeconfig entry..."
rm -f ~/.kube/config

# Generate kubeconfig entry
echo "Generating cluster config..."
gcloud container clusters get-credentials persona-brief-cluster --zone us-central1-a --project skillful-octane-360205

# Set namespace context
echo "Setting up namespace..."
kubectl config set-context --current --namespace persona-brief

# Install Cilium CLI
echo "Installing Cilium CLI..."
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvf cilium-linux-${CLI_ARCH}.tar.gz -C /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

# Enable Hubble UI
echo "Enabling Hubble UI..."
cilium hubble enable --ui

# Install Prometheus and Grafana
echo "Installing Prometheus and Grafana..."
if [ -f monitoring-example.yaml ]; then
    kubectl apply -f monitoring-example.yaml
else
    echo "monitoring-example.yaml not found. Please ensure it's available in the current directory."
    exit 1
fi

# Deploy application resources
echo "Starting app deployment..."
for resource in deployment.yaml service.yaml secret.yaml ingress.yaml; do
    if [ -f "$resource" ]; then
        kubectl apply -f "$resource"
    else
        echo "$resource not found. Please ensure it's available in the current directory."
        exit 1
    fi
done

# Wait for Ingress to become ready
echo "Waiting for Ingress to be ready..."
sleep 30

# Apply ClusterIssuer and Certificate
echo "Creating ClusterIssuer and Certificate..."
for cert_file in cluster_issuer.yaml certificate_create.yaml; do
    if [ -f "$cert_file" ]; then
        kubectl apply -f "$cert_file"
    else
        echo "$cert_file not found. Please ensure it's available in the current directory."
        exit 1
    fi
done

# Install Pixie
echo "Installing Pixie..."
bash -c "$(curl -fsSL https://work.withpixie.ai/install.sh)"

# Add Pixie to PATH globally
PIXIE_BIN="$HOME/bin"
if [ -d "$PIXIE_BIN" ]; then
    echo "Adding Pixie to PATH..."
    sudo cp "$PIXIE_BIN/px" /usr/local/bin/px
else
    echo "Pixie binary not found in $PIXIE_BIN"
    exit 1
fi

# # Verify Pixie installation
if command -v px &> /dev/null; then
    echo "Pixie installed successfully"
else
    echo "Failed to install Pixie"
    exit 1
fi

# Deploy Pixie
echo "Deploying Pixie..."
px auth login
px deploy

echo "Deployment completed successfully! 🚀"
