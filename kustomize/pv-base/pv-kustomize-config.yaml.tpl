apiVersion: v1
kind: ConfigMap
metadata:
  name: pv-kustomize-config
  namespace: "${TPL_NAMESPACE}" 
data:
  # In order for substitution to work, Volume Handles names/values MUST follow the following format:
  # {.metadata.name}-volume-handle: TPL_{upcase{.metadata.name}}_VOLUME_HANDLE
  # For example, the .metadata.name of the PersistentVolume resource on the next line is "disk-writer-pv"
  disk-writer-pd-volume-handle: "${TPL_DISK_WRITER_PV_VOLUME_HANDLE}"
  namespace: "bfg"
