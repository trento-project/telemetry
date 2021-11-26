#!/bin/sh
set -e

influx bucket create -n test-bucket --org-id ${DOCKER_INFLUXDB_INIT_ORG_ID} -r 4h