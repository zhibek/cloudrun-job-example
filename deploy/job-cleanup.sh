#!/usr/bin/env bash

# Stop on any error
set -x

# Set BASEDIR holding script path
BASEDIR=$(dirname "$0")

# Trigger job cleanup
gcloud builds submit \
  --config=${BASEDIR}/job-cleanup.yaml \
  --project ${PROJECT_ID} \
  ${BASEDIR}/..