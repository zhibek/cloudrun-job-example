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

# Set GCP project
echo "[PROJECT] Seting active GCP project"
gcloud config set project ${PROJECT_ID}

# Delete artifacts repository
echo "[ARTIFACTS] Checking repository..."
ARTIFACTS_EXISTS=$(gcloud artifacts repositories list --filter="name:${PROJECT_ID}" --format="get(name)")
if [ -n "${ARTIFACTS_EXISTS}" ]; then
  echo "[ARTIFACTS] Delete repository..."
  gcloud artifacts repositories delete \
    containers \
    --project=${PROJECT_ID} \
    --location=${REGION} \
    --quiet
fi

# Grant permissions to Cloud Build Service Account
echo "[SERVICE-ACCOUNT] Remove Cloud Run Admin role to Cloud Build service account"
SA_ROLE1_EXISTS=$(gcloud projects get-iam-policy ${PROJECT_ID} --flatten bindings --filter "bindings.role:roles/run.admin" --format="get(bindings.members)")
if [ -n "${SA_ROLE1_EXISTS}" ]; then
  gcloud projects remove-iam-policy-binding \
    ${PROJECT_ID} \
    --member "serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role roles/run.admin
fi
echo "[SERVICE-ACCOUNT] Remove IAM Service Account User role to Cloud Build service account on Cloud Run runtime service account"
SA_ROLE2_EXISTS=$(gcloud iam service-accounts get-iam-policy ${PROJECT_NUMBER}-compute@developer.gserviceaccount.com --flatten bindings --filter "bindings.role:roles/iam.serviceAccountUser" --format="get(bindings.members)")
if [ -n "${SA_ROLE2_EXISTS}" ]; then
  gcloud iam service-accounts remove-iam-policy-binding \
    ${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"
fi


# Keep this statement until the end!
echo "***** Destroy complete! *****"