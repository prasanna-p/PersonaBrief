#!/bin/bash

echo "deleting Kubernetes resources for PersonaBrief..."

echo "Uninstalling PersonaBrief Helm release..."
helm uninstall persona-brief --namespace persona-brief || echo "Helm release persona-brief not found."

echo "App removed"
