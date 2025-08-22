# Automated Cross-Region Disaster Recovery for Stateful GKE Workloads

Disclaimer: This is a solution sample that is not intended for production use. Please use it as a guide or open an issue if you would like to persue running this in production.

### About
This project provides a fully functional, sample solution that orchestrates automated disaster recovery for Stateful Workloads on Google Kubernetes Engine. The intended audience is organizations looking to provide hands-off disaster recovery in (very unlikely, but possible) event of a full Regional Google Cloud outage. 

# Technical Overview
The solution uses a mix of Backup for GKE and custom control plane elements to handle Persistent Disks Asynchronous Replication are used to demonstrate low RPO (seconds), RTO (~5 minutes) across 2 GCP Regions. Using Backup for GKE allows the solution backup entirely on a GKE clusters current state, as opposed to being dependant on a Continuous Delivery system (e.g. ArgoCD). 

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
