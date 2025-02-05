#!/bin/bash

echo "deleting Kubernetes resources for PersonaBrief..."

kubectl delete -f deployment.yaml
kubectl delete -f service.yaml
kubectl delete -f secret.yaml
kubectl delete -f ingress.yaml
sleep 30  # Ensure Ingress is created before cert-manager issues certs

kubectl delete -f cluster_issuer.yaml
kubectl delete -f certificate_create.yaml

echo "App removed"
