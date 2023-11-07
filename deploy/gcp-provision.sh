#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Require PROJECT_ID env var
if [ -z "${PROJECT_ID}" ]; then
  echo "ERROR: PROJECT_ID env var must be set!"
  exit 1
fi

# Set PROJECT_NUMBER based on PROJECT_ID
PROJECT_NUMBER=$(gcloud projects list --filter="projectId:${PROJECT_ID}" --format="get(projectNumber)")
if [ -z "${PROJECT_NUMBER}" ]; then
  echo "ERROR: Could not find PROJECT_NUMBER for PROJECT_ID '${PROJECT_ID}'"
  exit 1
fi

# Set REGION to default if not provided as env var
if [ -z "${REGION}" ]; then
  REGION="europe-west1"
fi

# Print inputs
echo "PROJECT_ID=${PROJECT_ID}"
echo "PROJECT_NUMBER=${PROJECT_NUMBER}"
echo "REGION=${REGION}"
echo ""

# Explain interactive requirement
AUTH_ACTIVE=$(gcloud auth print-access-token)
if [ -z "${AUTH_ACTIVE}" ]; then
  echo "ERROR: This provision script is designed to be run interactively!"
  echo "Please run the following login command before starting..."
  echo "gcloud auth login"
  exit 1
fi

# Checking project billing
echo "[BILLING] Checking billing account ID"
BILLING_ACCOUNT_ID=$(gcloud billing accounts list --filter=open:true --format="get(name)")
if [ -z "${BILLING_ACCOUNT_ID}" ]; then
  echo "ERROR: No billing project found!"
  exit 1
fi
echo "[BILLING] Checking project billing status"
PROJECT_BILLING_STATUS=$(gcloud billing projects list --billing-account=${BILLING_ACCOUNT_ID} --filter=projectId:${PROJECT_ID} --format="get(projectId,billingAccountName,billingEnabled)")
if [ -z "${PROJECT_BILLING_STATUS}" ]; then
  echo "[BILLING] Linking project to billing account"
  gcloud billing projects link ${PROJECT_ID} --billing-account=${BILLING_ACCOUNT_ID}
fi

# Set GCP project
echo "[PROJECT] Seting active GCP project"
gcloud config set project ${PROJECT_ID}

# Enable required service APIs
echo "[API] Activating Cloud Build service..."
gcloud services enable cloudbuild.googleapis.com
echo "[API] Activating Artifact Registry service..."
gcloud services enable artifactregistry.googleapis.com
echo "[API] Activating Cloud Run service..."
gcloud services enable run.googleapis.com

# Grant permissions to Cloud Build Service Account
echo "[SERVICE-ACCOUNT] Granting Cloud Run Admin role to Cloud Build service account"
gcloud projects add-iam-policy-binding \
  ${PROJECT_ID} \
  --member "serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role roles/run.admin
echo "[SERVICE-ACCOUNT] Granting IAM Service Account User role to Cloud Build service account on Cloud Run runtime service account"
gcloud iam service-accounts add-iam-policy-binding \
  ${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

# Checking Artifacts repository exists (creating if it doesn't)
echo "[ARTIFACTS] Checking repository..."
ARTIFACTS_EXISTS=$(gcloud artifacts repositories list --filter="name:${PROJECT_ID}" --format="get(name)")
if [ -z "${ARTIFACTS_EXISTS}" ]; then
  echo "[ARTIFACTS] Creating repository..."
  gcloud artifacts repositories create \
    containers \
    --project=${PROJECT_ID} \
    --repository-format=DOCKER \
    --location=${REGION}
fi


# Keep this statement until the end!
echo "***** Provision complete! *****"