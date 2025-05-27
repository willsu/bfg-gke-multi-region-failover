apiVersion: v1
kind: ConfigMap
metadata:
  name: kustomize-config
  namespace: bfg 
data:
  pd-size: "${PD_SIZE}"
  pd-volume-handle: "projects/${PROJECT_ID}/regions/${REGION}/disks/${PD_NAME}"
  namespace: "bfg"
  image-url: "us-docker.pkg.dev/${PROJECT_ID}/${DOCKER_REPO_NAME}/write-10g:v1"
