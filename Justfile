hack:
  kind create cluster --name=perf
  helm repo add camunda https://helm.camunda.io
  helm repo add chaos-mesh https://charts.chaos-mesh.org
  helm repo update
  helm install chaos-mesh chaos-mesh/chaos-mesh --create-namespace --namespace=chaos-mesh --version 2.5.1 --values hack/chaos-mesh-values.yaml
  helm install camunda-platform camunda/camunda-platform --create-namespace --namespace=camunda-platform --values hack/camunda-values.yaml

hack-cleanup:
  kind delete clusters perf