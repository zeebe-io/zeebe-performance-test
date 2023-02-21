#!/bin/sh
set -o errexit

definition=$(envsubst < experiments/"$CHAOS".yaml)

if [ -n "$GITHUB_STEP_SUMMARY" ]
then
    {
        echo "Deploying chaos $CHAOS"
        echo '```yaml'
        echo "$definition"
        echo '```'
    }  >> "$GITHUB_STEP_SUMMARY"
else
    echo "Deploying chaos $CHAOS"
fi

resource=$(echo "$definition" | kubectl apply -o name -f -)
echo "Waiting for $resource to be injected"
kubectl -n "$BENCHMARK_NAME" wait --for=condition=AllInjected "$resource"
echo "Waiting at least 1 minute for effects to become visible"
sleep 1m