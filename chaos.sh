#!/bin/sh
set -o errexit

definition=$(envsubst < experiments/"$CHAOS".yaml)

resource=$(echo "$definition" | kubectl apply -o name -f -)

if [ -n "$GITHUB_STEP_SUMMARY" ]
then
    {
        echo "Deployed chaos $CHAOS"
        echo '```yaml'
        echo "$definition"
        echo '```'
    }  >> "$GITHUB_STEP_SUMMARY"
fi

if [ -n "$GITHUB_OUTPUT" ]
then
    {
        echo "summary_markdown<<EOF"
        echo "Deployed chaos $CHAOS"
        echo "EOF"
    } >> "$GITHUB_OUTPUT"
    {
        echo "summary_slack<<EOF"
        echo "Deployed chaos $CHAOS"
        echo "EOF"
    } >> "$GITHUB_OUTPUT"
fi

echo "Deployed chaos $CHAOS"
echo "Waiting for $resource to be injected"
kubectl -n "$BENCHMARK_NAME" wait --for=condition=AllInjected "$resource"
echo "Waiting at least 1 minute for effects to become visible"
sleep 1m