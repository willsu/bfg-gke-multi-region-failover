apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: disk-writer-pvc # Name of your PVC
  namespace: ${NAMESPACE}
spec:
  # Storage class name MUST match the PV's storageClassName for static binding.
  # If the PV has storageClassName: "", this should also be "".
  storageClassName: manual
  # For static binding, you specify the 'volumeName' to bind to a specific PV.
  # This MUST match the 'metadata.name' of the PersistentVolume defined above.
  volumeName: disk-writer-pv
  # Access modes must match one of the access modes of the PV.
  accessModes:
    - ReadWriteOnce # Or ReadWriteOncePod, matching the PV
  # The requested storage must be less than or equal to the PV's capacity.
  resources:
    requests:
      storage: ${PD_SIZE} # IMPORTANT: This should generally match the PV's capacity for static binding
