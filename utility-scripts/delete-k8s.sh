set -ux

kubectl delete statefulset disk-writer-stateful-set -n $NAMESPACE &
kubectl delete service disk-writer-service -n $NAMESPACE &
kubectl delete service disk-writer-service-ilb -n $NAMESPACE &
kubectl delete pvc disk-writer-pvc -n $NAMESPACE &
kubectl delete configmaps kustomize-config -n $NAMESPACE &
kubectl delete configmaps pv-kustomize-config -n $NAMESPACE &
kubectl delete pv disk-writer-pv &
kubectl delete ns $NAMESPACE &
wait
