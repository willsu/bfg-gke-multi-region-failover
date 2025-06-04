apiVersion: v1
kind: ConfigMap
metadata:
  name: kustomize-config
  namespace: bfg 
data:
  namespace: "bfg"
  pd-size: "${PD_SIZE}"
  image-url: "us-docker.pkg.dev/${PROJECT_ID}/${DOCKER_REPO_NAME}/write-10g:v1"
