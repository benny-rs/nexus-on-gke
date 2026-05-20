#!/usr/bin/env bash

set -euo pipefail

PROJECT_ID="${1:?Usage: $0 <PROJECT_ID> <GCS_BUCKET_NAME> [REGION] [ZONE]}"
GCS_BUCKET="${2:?Usage: $0 <PROJECT_ID> <GCS_BUCKET_NAME> [REGION] [ZONE]}"
REGION="${3:-asia-southeast2}"
ZONE="${4:-asia-southeast2-a}"

IMAGE="gcr.io/${PROJECT_ID}/nexus3-gcs:3.68.0"
CLUSTER_NAME="nexus-cluster"
NAMESPACE="nexus"

echo "==> Configuring gcloud project"
gcloud config set project "${PROJECT_ID}"

# ---------------------------------------------------------------------------
# Step 1 — Build & push custom Docker image
# ---------------------------------------------------------------------------
echo "==> Building custom Nexus image"
docker build -t "${IMAGE}" docker/

echo "==> Authenticating Docker to GCR"
gcloud auth configure-docker --quiet

echo "==> Pushing image to GCR"
docker push "${IMAGE}"

# ---------------------------------------------------------------------------
# Step 2 — Provision GCP infrastructure with Terraform
# ---------------------------------------------------------------------------
echo "==> Initialising Terraform"
cd terraform
terraform init -input=false

echo "==> Applying Terraform (this takes ~5-10 min)"
terraform apply -input=false -auto-approve \
  -var="project_id=${PROJECT_ID}" \
  -var="gcs_bucket_name=${GCS_BUCKET}" \
  -var="region=${REGION}" \
  -var="zone=${ZONE}"

cd ..

# ---------------------------------------------------------------------------
# Step 3 — Configure kubectl
# ---------------------------------------------------------------------------
echo "==> Fetching GKE credentials"
gcloud container clusters get-credentials "${CLUSTER_NAME}" \
  --zone "${ZONE}" --project "${PROJECT_ID}"

# ---------------------------------------------------------------------------
# Step 4 — Helm deploy
# ---------------------------------------------------------------------------
echo "==> Creating Kubernetes namespace"
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "==> Installing / upgrading Nexus via Helm"
helm upgrade --install nexus k8s/helm/nexus \
  --namespace "${NAMESPACE}" \
  --set image.repository="gcr.io/${PROJECT_ID}/nexus3-gcs" \
  --set image.tag="3.68.0" \
  --set gcs.bucketName="${GCS_BUCKET}" \
  --set "serviceAccount.annotations.iam\\.gke\\.io/gcp-service-account=nexus-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --wait --timeout=8m

# ---------------------------------------------------------------------------
# Step 5 — Print access info
# ---------------------------------------------------------------------------
echo ""
echo "==> Waiting for LoadBalancer IP…"
kubectl get svc nexus -n "${NAMESPACE}" --watch &
WATCH_PID=$!
sleep 30
kill ${WATCH_PID} 2>/dev/null || true

EXTERNAL_IP=$(kubectl get svc nexus -n "${NAMESPACE}" \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "<pending>")

echo ""
echo "======================================================"
echo "  Nexus UI:  http://${EXTERNAL_IP}:8081"
echo "  Default admin password stored in:"
echo "    kubectl exec -n ${NAMESPACE} deploy/nexus -- cat /nexus-data/admin.password"
echo "======================================================"
