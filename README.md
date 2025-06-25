# bfg-gke-multi-region-failover

Highly Experimental.. Please ignore

Assumptions
* In a complete regional failure, we cannot depend on any information from the source region (e.g Persistent Disks in the Cloud Console, GKE cluster configurations, etc)
* Persistent Disks with cross-region asynchronous replication must be managed outside of GKE and brought into the cluser through Static Volume Provision.
  * This includes the process to stop/start replication during in the event of a failover.

Goals
* Invoking the failover script should require as little configuration as possible.
* The failover script may be invoked manually or through an automated mechanism (such as a Cloud Monitoring alert).

TODO Ideas:
* Cloud Run Job that executes a manual "Backup for GKE" backup and then reads the Persistent Disk handles from the Persistent Volume resources. The Persistent Disk handles will be stored in a Cloud Object storage buckets that will be connected by naming convention to the specific "Backup for GKE" backup taken within the same Cloud Run Job.
  * The Persistent Volume k8s resources will be tagged (e.g. "cross-region-async") to ease the implementation parsing the YAML to resolve the in-use Persistent Disk.
  * The Persistent Disks YAML will be keyed-off by the ".metadata.name" field of their k8s resources. (TODO: find a way to correlate this back to the relevant envsub resource).
  * Cloud Run Job ensures that there is not already a BfG backup in progress, and will exit immediately if there is. 
