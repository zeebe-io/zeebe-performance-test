#!/bin/sh
set -o errexit

url=https://monitoring.googleapis.com/v1/projects/zeebe-io/location/global/prometheus/api/v1/query
token=$(gcloud auth print-access-token)

run_query() {
    until result=$(curl $url -d "query=$1" -H "Authorization: Bearer $token" | jq '.data.result[0].value[1] | tonumber')
    do
        echo "Failed to query, retrying..."
        sleep 1
    done
    echo "$result"
}

# Queries
process_latency_99=$(run_query "histogram_quantile(0.99, sum(rate(zeebe_process_instance_execution_time_bucket{namespace=\"$BENCHMARK_NAME\"}[5m])) by (le))")
process_latency_90=$(run_query "histogram_quantile(0.90, sum(rate(zeebe_process_instance_execution_time_bucket{namespace=\"$BENCHMARK_NAME\"}[5m])) by (le))")
process_latency_50=$(run_query "histogram_quantile(0.50, sum(rate(zeebe_process_instance_execution_time_bucket{namespace=\"$BENCHMARK_NAME\"}[5m])) by (le))")

process_latency_99=$(run_query "histogram_quantile(0.99, sum(rate(zeebe_process_instance_execution_time_bucket{namespace=\"$BENCHMARK_NAME\"}[5m])) by (le))")
process_latency_90=$(run_query "histogram_quantile(0.90, sum(rate(zeebe_process_instance_execution_time_bucket{namespace=\"$BENCHMARK_NAME\"}[5m])) by (le))")
process_latency_50=$(run_query "histogram_quantile(0.50, sum(rate(zeebe_process_instance_execution_time_bucket{namespace=\"$BENCHMARK_NAME\"}[5m])) by (le))")

throughput=$(run_query "sum(rate(zeebe_element_instance_events_total{namespace=\"$BENCHMARK_NAME\",  action=\"completed\", type=\"PROCESS\"}[5m]))")

if [ -n "$GITHUB_STEP_SUMMARY" ]
then
    echo "**Process Instance Execution Time**: p99=$process_latency_99 p90=$process_latency_90 p50=$process_latency_50" >> "$GITHUB_STEP_SUMMARY"
    echo "**Throughput**: $throughput PI/s"
else
    echo "Process Instance Execution Time: p99=$process_latency_99 p90=$process_latency_90 p50=$process_latency_50"
    echo "Throughput: $throughput PI/s"
fi
