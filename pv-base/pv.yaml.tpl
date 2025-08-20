apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${TPL_PV_NAME} # Placeholder for TPL_PV_NAME
  labels:
    pd-type: cross-region-async # Label required for failover script
spec:
  # Capacity must match or be greater than the PVC's request
  capacity:
    storage: "${TPL_PV_STORAGE_CAPACITY}"
  accessModes:
    - ReadWriteOnce # Or ReadWriteOncePod if using GKE Autopilot
  storageClassName: manual
  persistentVolumeReclaimPolicy: Retain
  # GCE Persistent Disk specific configuration
  csi:
    driver: pd.csi.storage.gke.io
    volumeHandle: ${TPL_PV_VOLUME_HANDLE} # Placeholder for TPL_PV_VOLUME_HANDLE
    fsType: ext4
