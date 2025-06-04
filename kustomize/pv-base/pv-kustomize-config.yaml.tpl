apiVersion: v1
kind: ConfigMap
metadata:
  name: pv-kustomize-config
  namespace: "${NAMESPACE}" 
data:
  pd-size: "${PD_SIZE}"
  pd-volume-handle: "projects/${PROJECT_ID}/regions/${REGION}/disks/${PD_NAME}"
  namespace: "bfg"
