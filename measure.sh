#!/bin/sh
set -o errexit

url=https://monitoring.googleapis.com/v1/projects/zeebe-io/location/global/prometheus/api/v1/query
token=$(gcloud auth print-access-token)

# Query helpers
percentile() {
    echo "histogram_quantile($1, $2)"
}
stddev() {
    echo "stddev_over_time(($1)[3m:])"
}

run_query() {
    until result=$(curl -s $url -d "query=$1" -H "Authorization: Bearer $token" | jq '.data.result[0].value[1] | tonumber')
    do
        echo "Failed to query, retrying..."
        sleep 5
    done

    result=$(echo "$result" | awk '{ printf("%.3f",$1) }')
    echo "$result"
}

wait_for_query_value() {
    result=0

    until [ "$result" -eq 1 ]
    do
        sleep 10
        limitOfRetries=0
        value=$(curl -s $url -d "query=$1" -H "Authorization: Bearer $token" | jq ' try .data.result[0].value[1] | tonumber')
        until [ ! -z "$value" ]
        do

          # tries to query the endpoint for a maximum of 5 minutes
          if [ $limitOfRetries -eq 30 ]
          then
            echo "Error querying endpoint $url"
            exit 1
          fi

          echo "Failed to query to endpoint $url, retrying..."
          sleep 10
          value=$(curl -s $url -d "query=$1" -H "Authorization: Bearer $token" | jq 'try .data.result[0].value[1] | tonumber')
          ((limitOfRetries=limitOfRetries+1))
        done
        result=$(echo "$value $2 $3" | bc)
        printf "\r %g %s %g: %s" "$value" "$2" "$3" "$result"
    done
    printf "\n"
}

# Query definitions
latency="sum by (le) (rate(zeebe_process_instance_execution_time_bucket{namespace=\"$BENCHMARK_NAME\"}[3m]))"
throughput="sum(rate(zeebe_element_instance_events_total{namespace=\"$BENCHMARK_NAME\",  action=\"completed\", type=\"PROCESS\"}[3m]))"

# Wait until metrics are stable
start_time=$(date +%s%3N)
stable_latency="$(stddev "$(percentile 0.99 "$latency")")"
stable_throughput="$(stddev "$throughput")"

echo "Waiting for minimal throughput"
wait_for_query_value "$throughput" \> 5 

echo "Waiting for stable process instance execution times (stddev < 0.5)"
wait_for_query_value "$stable_latency" \< 0.5

echo "Waiting for stable throughput (stddev < 0.5)"
wait_for_query_value "$stable_throughput" \< 0.5

# Measure
process_latency_99=$(run_query "$(percentile 0.99 "$latency")")
process_latency_90=$(run_query "$(percentile 0.90 "$latency")")
process_latency_50=$(run_query "$(percentile 0.50 "$latency")")

throughput_avg=$(run_query "$throughput")
end_time=$(date +%s%3N)
grafana_url="https://grafana.dev.zeebe.io/d/zeebe-dashboard/zeebe?orgId=1&var-namespace=$BENCHMARK_NAME&from=$start_time&to=$end_time"


if [ -n "$GITHUB_STEP_SUMMARY" ]
then
    {
        echo "**Process Instance Execution Time**: p99=$process_latency_99 p90=$process_latency_90 p50=$process_latency_50"
        echo "**Throughput**: $throughput_avg PI/s" 
        echo "[Grafana Dashboard]($grafana_url)"
    } >> "$GITHUB_STEP_SUMMARY"
fi
if [ -n "$GITHUB_OUTPUT" ]
then
    {
        echo "summary_markdown<<EOF"
        echo "**Process Instance Execution Time**: p99=$process_latency_99 p90=$process_latency_90 p50=$process_latency_50"
        echo "**Throughput**: $throughput_avg PI/s"
        echo "[Grafana]($grafana_url)"
        echo "EOF"
    } >> "$GITHUB_OUTPUT"
    {
        echo "summary_slack<<EOF"
        echo "*Process Instance Execution Time*: p99=$process_latency_99 p90=$process_latency_90 p50=$process_latency_50"
        echo "*Throughput*: $throughput_avg PI/s"
        echo "<$grafana_url|Grafana>"
        echo "EOF"
    } >> "$GITHUB_OUTPUT"
fi

echo "Process Instance Execution Time: p99=$process_latency_99 p90=$process_latency_90 p50=$process_latency_50"
echo "Throughput: $throughput_avg PI/s"
