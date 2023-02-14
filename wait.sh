#!/bin/sh
set -o errexit

kubectl -n "$BENCHMARK_NAME" rollout status statefulset "$BENCHMARK_NAME"-zeebe
kubectl -n "$BENCHMARK_NAME" create job --from=cronjob/leader-balancer manual-rebalancing-"$(date +%s)"