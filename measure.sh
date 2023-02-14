#!/bin/sh
set -o errexit

url=https://monitoring.googleapis.com/v1/projects/zeebe-io/location/global/prometheus/api/v1/query
token=$(gcloud auth print-access-token)

# Queries
process_latency_99="histogram_quantile(0.99, sum(rate(zeebe_process_instance_execution_time_bucket{namespace=\"$BENCHMARK_NAME\"}[5m])) by (le))"
process_latency_90="histogram_quantile(0.90, sum(rate(zeebe_process_instance_execution_time_bucket{namespace=\"$BENCHMARK_NAME\"}[5m])) by (le))"
process_latency_50="histogram_quantile(0.50, sum(rate(zeebe_process_instance_execution_time_bucket{namespace=\"$BENCHMARK_NAME\"}[5m])) by (le))"

until p99=$(curl $url -d "query=$process_latency_99" -H "Authorization: Bearer $token" | jq '.data.result[0].value[1] | tonumber')
do
    echo "Failed to query, retrying..."
    sleep 1
done
until p90=$(curl $url -d "query=$process_latency_90" -H "Authorization: Bearer $token" | jq '.data.result[0].value[1] | tonumber')
do
    echo "Failed to query, retrying..."
    sleep 1
done
until p50=$(curl $url -d "query=$process_latency_50" -H "Authorization: Bearer $token" | jq '.data.result[0].value[1] | tonumber')
do
    echo "Failed to query, retrying..."
    sleep 1
done


if [ -n "$GITHUB_STEP_SUMMARY" ]
then
    echo "*Process Instance Execution Time*: p99=$p99 p90=$p90 p50=$p50" >> "$GITHUB_STEP_SUMMARY"
else
    echo "Process Instance Execution Time: p99=$p99 p90=$p90 p50=$p50"
fi
