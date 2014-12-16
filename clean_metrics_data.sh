#!/bin/bash

source /env.profile
echo "===="
echo ${NODE_METRICS_URL}
echo ${CONTAINER_METRICS_URL}
echo "====="

CLEAN_CONTAINER_METRICS="curl -sGkfL '${CONTAINER_METRICS_URL}' --data-urlencode 'q=delete from stats where time < now() - ${DATA_CLEAN_SINCE}'"
CLEAN_NODE_METRICS="curl -sGkfL '${NODE_METRICS_URL}' --data-urlencode 'q=delete from stats where time < now() - ${DATA_CLEAN_SINCE}'"
echo ${CLEAN_CONTAINER_METRICS}
echo ${CLEAN_NODE_METRICS}
eval ${CLEAN_CONTAINER_METRICS}
eval ${CLEAN_NODE_METRICS}
