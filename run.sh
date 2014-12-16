#!/bin/bash

add_ac() {
    echo "$1" | grep -F "into stats.2h" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Found existing $5 hours downsampling continuous query, skip"
    else
        echo "About to add $5 downsampling continuous query"
        ADD_CQ="curl -sGkfL '$2' --data-urlencode 'q=select $3 from stats group by time($4) into stats.$4'"
        eval ${ADD_CQ} >/dev/null
        if [ $? -eq 0 ]; then
            echo "$5 downsampling continuous query has been added to container metrics database in influxdb"
        else
            echo "Failed to $5 downsampling continuous query"
        fi
    fi
}

MNT_PNT="/var/lib/docker"

MSG="$(df -mT /var/lib/docker 2>&1)"
RET="$?"
if [ ${RET} -ne 0 ]; then
    echo "=> ${MSG}"
    echo "=> Cannot get disk usage. Please check if volume ${MNT_PNT} is mounted or not, exiting ..."
    exit 1
fi

if [ -n "${INFLUXDB_PORT_8086_TCP_ADDR}" ] && [ -n "${INFLUXDB_PORT_8086_TCP_PORT}" ]; then
    DBHOST=${INFLUXDB_PORT_8086_TCP_ADDR}
    DBPORT=${INFLUXDB_PORT_8086_TCP_PORT}
    DBNAME=${DB_NAME}
    DBUSER=${DB_USER}
    DBPASS=${INFLUXDB_ENV_INFLUXDB_INIT_PWD:-${DB_PASS}}
    echo "====INFLUX DB SPEC====="
    echo "  host:${DBHOST}:${DBPORT}"
    echo "  name:${DBNAME}"
    echo "  user:${DBUSER}"
    echo "  pass:${DBPASS}"
    echo "====INFLUX DB SPEC===="
else
    echo "=> Not link to any influxdb container. exiting ..."
    exit 1
fi


NODE_METRICS_URL="http://${DBHOST}:${DBPORT}/db/${DBNAME}/series?u=${DBUSER}&p=${DBPASS}"
CONTAINER_METRICS_URL="http://${DBHOST}:${DBPORT}/db/cadvisor/series?u=${DBUSER}&p=${DBPASS}"

#Testing if IfluxDB is reachable
echo "Test if InfluxDB is reachable"
TEST_DB="curl -sGkfL '${CONTAINER_METRICS_URL}' --data-urlencode 'q=list series'"
eval ${TEST_DB} >/dev/null || exit 1
TEST_DB="curl -sGkfL '${NODE_METRICS_URL}' --data-urlencode 'q=list series'"
eval ${TEST_DB} >/dev/null || exit 1
echo "Successfully connect to InfluxDB"

echo "export NODE_METRICS_URL=\"${NODE_METRICS_URL}\"" > /env.profile
echo "export CONTAINER_METRICS_URL=\"${CONTAINER_METRICS_URL}\"" >> /env.profile

# Add contiuous queries to container metrics
echo "Adding downsampling continuous queries to container metrics database in influxdb:"
LIST_CQ_STR="curl -sGkfL '${CONTAINER_METRICS_URL}' --data-urlencode 'q=list continuous queries' "
LIST_CQ=$(eval ${LIST_CQ_STR})
FIELD="mean(cpu_cumulative_usage) as cpu_cumulative_usage, mean(memory_working_set) as memory_working_set, max(rx_bytes) as rx_bytes, max(tx_bytes) as tx_bytes"

add_ac "${LIST_CQ}" "${CONTAINER_METRICS_URL}" "${FIELD}" "1m" "1 minute"
add_ac "${LIST_CQ}" "${CONTAINER_METRICS_URL}" "${FIELD}" "5m" "5 minutes"
add_ac "${LIST_CQ}" "${CONTAINER_METRICS_URL}" "${FIELD}" "30m" "30 minutes"
add_ac "${LIST_CQ}" "${CONTAINER_METRICS_URL}" "${FIELD}" "2h" "2 hours"
add_ac "${LIST_CQ}" "${CONTAINER_METRICS_URL}" "${FIELD}" "1d" "1 day"

# Add contiuous queries to node metrics
echo "Adding downsampling continuous queries to node metrics database in influxdb:"
LIST_CQ_STR="curl -sGkfL '${NODE_METRICS_URL}' --data-urlencode 'q=list continuous queries'"
LIST_CQ=$(eval ${LIST_CQ_STR})
FIELD="mean(cpuusage) as cpuusage, mean(diskused) as diskused, max(disksize) as disksize, mean(memused) as memused, max(memsize) as memsize, max(rxbytes) as rxbytes, max(txbytes) as txbytes"

add_ac "${LIST_CQ}" "${NODE_METRICS_URL}" "${FIELD}" "1m" "1 minute"
add_ac "${LIST_CQ}" "${NODE_METRICS_URL}" "${FIELD}" "5m" "5 minutes"
add_ac "${LIST_CQ}" "${NODE_METRICS_URL}" "${FIELD}" "30m" "30 minutes"
add_ac "${LIST_CQ}" "${NODE_METRICS_URL}" "${FIELD}" "2h" "2 hours"
add_ac "${LIST_CQ}" "${NODE_METRICS_URL}" "${FIELD}" "1d" "1 day"
