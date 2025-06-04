set -ux

kubectl delete deployments disk-writer-deployment -n $NAMESPACE
kubectl delete pvc disk-writer-pvc -n $NAMESPACE
kubectl delete configmaps kustomize-config -n $NAMESPACE
kubectl delete configmaps pv-kustomize-config -n $NAMESPACE
kubectl delete pv disk-writer-pv

