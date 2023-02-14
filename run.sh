#!/bin/sh
set -o errexit

setup() {
    helm repo add zeebe-benchmark https://zeebe-io.github.io/benchmark-helm
    helm repo add chaos-mesh https://charts.chaos-mesh.org
    helm upgrade --install chaos-mesh \
        chaos-mesh/chaos-mesh --version 2.5.1 \
        --namespace=chaos-mesh --create-namespace \
        --set dashboard.securityMode=false \
        --set chaosDaemon.runtime=containerd \
        --set chaosDaemon.socketPath=/var/run/containerd/containerd.sock
    helm upgrade --install "$BENCHMARK_NAME" \
        zeebe-benchmark/zeebe-benchmark \
        --namespace="$BENCHMARK_NAME" --create-namespace
    kubectl -n "$BENCHMARK_NAME" rollout status statefulset "$BENCHMARK_NAME"-zeebe
    kubectl -n "$BENCHMARK_NAME" create job --from=cronjob/leader-balancer manual-rebalancing 
}

measure() {
    url=https://monitoring.googleapis.com/v1/projects/zeebe-io/location/global/prometheus/api/v1/query
    token=$(gcloud auth print-access-token)

    # Queries
    process_latency_99="histogram_quantile(0.99, sum(rate(zeebe_process_instance_execution_time_bucket{namespace=\"$BENCHMARK_NAME\"}[5m])) by (le))"
    process_latency_90="histogram_quantile(0.90, sum(rate(zeebe_process_instance_execution_time_bucket{namespace=\"$BENCHMARK_NAME\"}[5m])) by (le))"
    process_latency_50="histogram_quantile(0.50, sum(rate(zeebe_process_instance_execution_time_bucket{namespace=\"$BENCHMARK_NAME\"}[5m])) by (le))"

    p99=$(curl -sSL $url -d "query=$process_latency_99" -H "Authorization: Bearer $token" | jq '.data.result[0].value[1] | tonumber')
    p90=$(curl -sSL $url -d "query=$process_latency_90" -H "Authorization: Bearer $token" | jq '.data.result[0].value[1] | tonumber')
    p50=$(curl -sSL $url -d "query=$process_latency_50" -H "Authorization: Bearer $token" | jq '.data.result[0].value[1] | tonumber')
    printf "Process Instance Execution Time: p99=%s p90=%s p50=%s\n", "$p99", "$p90", "$p50" 
}

setup
sleep 5m
measure
envsubst < experiments/network-latency-35.yaml | kubectl apply -f -
sleep 5m
measure