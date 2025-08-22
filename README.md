# Automated Cross-Region Disaster Recovery for Stateful GKE Workloads

Disclaimer: This is a solution sample that is not intended for production use. Please use it as a guide or open an issue if you would like to persue running this in production.

### About
This project provides a fully functional, sample solution that orchestrates automated disaster recovery for Stateful Workloads on Google Kubernetes Engine. The intended audience is organizations looking to provide hands-off disaster recovery in (very unlikely, but possible) event of a full Regional Google Cloud outage. 

### Technical Overview
The solution uses a mix of Backup for GKE and custom control plane elements to handle Persistent Disks Asynchronous Replication are used to demonstrate low RPO (seconds), RTO (~5 minutes) across 2 GCP Regions. Using Backup for GKE allows the solution backup entirely on a GKE clusters current state, as opposed to being dependant on a Continuous Delivery system (e.g. ArgoCD). 

Figure 1: Architecture Diagram
<img width="2311" height="1371" alt="Automated Cross-Region DR Failover on GKE" src="https://github.com/user-attachments/assets/6d186c38-6456-4d7f-846b-64bdc9a0aa4e" />

### Setup

Prerequirements:
* Google Cloud Account
* gcloud SDK

Installation Instructions:
1) Optional: review the "configure.sh" file and determine if the variable values meet your neeeds. 

2) Run the `setup-all` script to provision all the Google Cloud resources 
```BASH
./setup-all
```
Estimated Time for Completion: 20 minutes

### Usage

Scenario 1:

Setup
1) Open the Cloud Run Services and navigate to the "disk-client" service
2) Open the Cloud Run generated link to the "disk-client" application
3) Choose a number of bytes to write to disk (e.g. 52428800 for 50 MB) and click "Submit"
4) Note that Region and Host information are pointing to the Region of us-central1

Disaster Recovery
1) Delete the cluster in the us-central1 Region
2) Wait ~5 minutes
3) Refresh the "disk-client" application.
4) You should see the same number of bytes and the Region and Host information pointing to the Region of us-west1
