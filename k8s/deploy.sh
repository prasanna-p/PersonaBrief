#!/bin/bash

echo "Applying Kubernetes resources for PersonaBrief..."

kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f secret.yaml
kubectl apply -f ingress.yaml

echo "Waiting for Ingress to be ready..."
sleep 30  # Ensure Ingress is created before cert-manager issues certs

kubectl apply -f cluster_issuer.yaml
kubectl apply -f certificate_create.yaml

echo "Deployment completed successfully!"
