#!/bin/sh
set -o errexit


if [ -n "$GITHUB_STEP_SUMMARY" ]
then
    echo "Deploying chaos $CHAOS" >> "$GITHUB_STEP_SUMMARY"
else
    echo "Deploying chaos $CHAOS"
fi

envsubst < experiments/"$CHAOS".yaml | kubectl apply -f -