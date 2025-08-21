#!/bin/bash
set -eux

gcloud services enable \
  run.googleapis.com \
  compute.googleapis.com \
  container.googleapis.com \
  dns.googleapis.com \
  cloudscheduler.googleapis.com \
  gkebackup.googleapis.com \
  eventarc.googleapis.com \
  orgpolicy.googleapis.com
