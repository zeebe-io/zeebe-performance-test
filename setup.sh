#!/bin/sh
set -o errexit

kubectl delete ns "$BENCHMARK_NAME"
helm repo add zeebe-benchmark https://zeebe-io.github.io/benchmark-helm
helm install "$BENCHMARK_NAME" \
    zeebe-benchmark/zeebe-benchmark \
    --namespace="$BENCHMARK_NAME" --create-namespace
