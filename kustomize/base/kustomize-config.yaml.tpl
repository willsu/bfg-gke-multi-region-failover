apiVersion: v1
kind: ConfigMap
metadata:
  name: kustomize-config
  namespace: bfg 
data:
  pd-size: "50Gi"
  pd-name: "bfg-demo-disk"
  namespace: "bfg"
  image-url: "us-docker.pkg.dev/will-gke-multi-region-bfg/bfg-demo/write-10g:v1"
