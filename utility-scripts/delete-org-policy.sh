#!/bin/bash
set -eux

gcloud org-policies delete constraints/compute.resourceLocations

