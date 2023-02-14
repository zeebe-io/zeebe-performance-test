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

echo "$definition" | kubectl apply -f -