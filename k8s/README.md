# PersonaBrief Kubernetes Deployment Guide

## **Overview**
This documentation outlines the deployment process for PersonaBrief on a Kubernetes cluster using Terraform and Helm.

---
## **Prerequisites**
- **Google Cloud Project** with billing enabled.
- **APIs to Enable:** Kubernetes API, IAM API, Service Usage API.
- **User Roles Required:** API Management Admin, Compute Admin, Kubernetes Engine Admin, Project IAM Admin, Role Viewer, Service Account Admin, Service Account User, Service Usage Consumer.

---
## **Tools Required**
- Use **Google Cloud Shell** (pre-installed with `gcloud`, `kubectl`, `helm`, and `terraform`).
- **Cilium** and **Pixie** installed via automated script.

---
## **Terraform Deployment**
1. **Create `terraform.tfvars` within terraform root directory and setup below vars**:
   ```hcl
   project_id           = "your gcp project id"
   service_account_name = "personabrief"
   ```
2. **Initialize and Deploy:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
   - Deploys a 2-node GKE cluster (`e2-standard-2` machine type).
   - Creates IAM service account (`Vertex AI User`, `Artifact Registry Reader` roles).
   - Sets up namespace, service account, Workload Identity.
   - Installs Cilium, Cert-Manager, Ingress Controller.

---
## **Build and Push Docker Image**
1. Create artifact repo in us-central region
2. Run below command in cloud shell to setup artifact repo
   ```bash
   gcloud auth configure-docker \
    us-central1-docker.pkg.dev
   ```
3. Navigate to `app/` directory.
4. Build and push the image:
   ```bash
   docker build -t us-central1-docker.pkg.dev/<project_name>/<repo_name>/<image_name>:v1 .
   docker push us-central1-docker.pkg.dev/<project_name>/<repo_name>/<image_name>:v1
   ```

---
## **Create `.env` File**
```env
API_KEY=<API_KEY_DETAILS>
SEARCH_ENGINE_ID=<search_engine_id>
PROJECT_ID=<GCP_PROJECT_NAME>
LOCATION=us-central1
SERVICE_ACCOUNT=persona-brief-ksa
HOST_NAME_URL=<url_name>
REPO_NAME=<artifact_repo_url>
TAG=v3
NAMESPACE=persona-brief
USER_EMAIL=<user_email>
ZONE=us-central1-a
CLUSTER_NAME=persona-brief-cluster
```
- this .env file should be created within k8s folder.

---
## **Register for Pixie Monitoring**
- Register at [Pixie](https://work.withpixie.ai/live) with your email (Pixie is free and open-source).

---
## **Run `deploy.sh` Script**
```bash
sh deploy.sh
```
- **Sets up namespace:** `persona-brief`.
- **Installs:** Cilium (with Hubble UI), Prometheus, Grafana (integrated with Cilium for metrics).
- **Substitutes variables** from `.env` to `values.yaml`.
- **Deploys PersonaBrief** via Helm.
- **Installs Pixie:** 
  - Accept terms (`yes`), 
  - Provide Pixie auth token when prompted.

---
## **Accessing PersonaBrief**
1. **Get Ingress IP:**
   ```bash
   kubectl get ingress
   ```
2. **Domain Setup:**
   - For custom URL: Add entry to `/etc/hosts`.
   - For purchased domain: Create an `A` record pointing to the Ingress IP.
3. **Check Certificate Assignment:**
   ```bash
   kubectl get secrets
   ```
   Ensure a secret ending with `tls` is present.
4. **Access Site:** Open the domain URL and start searching names!

---
## ✅ **Deployment Complete!**
