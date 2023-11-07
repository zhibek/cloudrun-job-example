# Cloud Run - Job Example

## Prerequisites

### Create Google Cloud Project
[https://console.cloud.google.com/projectcreate]

### Install Google Cloud CLI
[https://cloud.google.com/sdk/docs/install]

### Login to Google Cloud on CLI
```
gcloud auth login
```


## GCP Environment

### Provision
Provision GCP with the services and configuration required to use Cloud Run.
```
PROJECT_ID=cloudrun-job-example deploy/gcp-provision.sh
```

### Destroy
Destroy the GCP environment when it is no longer required.
```
PROJECT_ID=cloudrun-job-example deploy/gcp-destroy.sh
```


## Cloud Run Job

### Setup
Setup the Cloud Run job to install the latest code.
```
PROJECT_ID=cloudrun-job-example deploy/job-setup.sh
```

### Run
Run the Cloud Run job to execute the logic.
```
PROJECT_ID=cloudrun-job-example deploy/job-run.sh
```

### Cleanup
Cleanup the Cloud Run job when it is no longer required.
```
PROJECT_ID=cloudrun-job-example deploy/job-cleanup.sh
```


