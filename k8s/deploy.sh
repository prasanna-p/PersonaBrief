#!/bin/bash

echo "Applying Kubernetes resources for PersonaBrief..."

rm ~/.kube/config

# generate kubeconfig entry
gcloud container clusters get-credentials persona-brief-cluster --zone us-central1-a --project skillful-octane-360205

# setup namespace
kubectl config set-context --current --namespace persona-brief

# install cilium command line unitility
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

#enable hubble ui
cilium hubble enable --ui

kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f secret.yaml
kubectl apply -f ingress.yaml

echo "Waiting for Ingress to be ready..."
sleep 30  # Ensure Ingress is created before cert-manager issues certs

kubectl apply -f cluster_issuer.yaml
kubectl apply -f certificate_create.yaml

echo "Deployment completed successfully!"
