#!/bin/sh
set -o errexit

./setup.sh
./measure.sh
./chaos.sh
./measure.sh