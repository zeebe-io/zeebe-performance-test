#!/bin/sh
set -o errexit

./setup.sh
./wait.sh
./measure.sh
./chaos.sh
./wait.sh
./measure.sh