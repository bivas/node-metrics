#!/bin/bash

source /env.profile

CLEAN_CONTAINER_METRICS="curl -sGkfL '${CONTAINER_METRICS_URL}' --data-urlencode 'q=delete from stats where time < now() - ${DATA_CLEAN_SINCE}'"
CLEAN_NODE_METRICS="curl -sGkfL '${NODE_METRICS_URL}' --data-urlencode 'q=delete from stats where time < now() - ${DATA_CLEAN_SINCE}'"
echo -n "$(date): Cleaning container metrics data. "
eval ${CLEAN_CONTAINER_METRICS}
echo ""
echo -n "$(date): Cleaning node metrics data. "
eval ${CLEAN_NODE_METRICS}
echo ""
