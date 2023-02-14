#!/bin/sh
set -o errexit

helm repo add zeebe-benchmark https://zeebe-io.github.io/benchmark-helm
helm upgrade --install "$BENCHMARK_NAME" \
    zeebe-benchmark/zeebe-benchmark \
    --namespace="$BENCHMARK_NAME" --create-namespace
