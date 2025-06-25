apiVersion: v1
kind: ConfigMap
metadata:
  name: pv-kustomize-config
  namespace: "${TPL_NAMESPACE}" 
data:
  disk-writer-pd-volume-handle: "${TPL_DISK_WRITER_PV_VOLUME_HANDLE}"
  namespace: "bfg"
