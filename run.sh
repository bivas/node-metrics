#!/bin/bash

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


POSTURL="http://${DBHOST}:${DBPORT}/db/${DBNAME}/series?u=${DBUSER}&p=${DBPASS}"

echo "Test if InfluxDB is reachable"
TEST_DB="curl -GkfL '${POSTURL}' --data-urlencode 'q=list series'"
echo "${TEST_DB}"
eval ${TEST_DB} || exit 1
echo ""
echo "Successfully connect to InfluxDB"

trap '{ echo "User Interupt."; exit 1; }' INT
while [ 1 ]
do
    MSG="$(df -mT /var/lib/docker 2>&1)"
    DISK_SIZE=$(echo "${MSG}" | tail -n 1 | awk '{print $3}')
    DISK_USED=$(echo "${MSG}" | tail -n 1 | awk '{print $4}')
    DISK_FREE=$(echo -mT "${MSG}" | tail -n 1 | awk '{print $5}')
    DISK_PERCENTAGE=$(echo "${MSG}" | tail -n 1 | awk '{print $6}'| rev | cut -c 2- | rev )

    MSG="$(free -m)"
    MEM_SIZE=$(echo "${MSG}" | awk 'NR==2 {print $2}')
    MEM_USED=$(echo "${MSG}" | awk 'NR==3 {print $3}')
    MEM_FREE=$(echo "${MSG}" | awk 'NR==3 {print $4}')
    SWAP_SIZE=$(echo "${MSG}" | awk 'NR==4 {print $2}')
    SWAP_USED=$(echo "${MSG}" | awk 'NR==4 {print $3}')
    SWAP_FREE=$(echo "${MSG}" | awk 'NR==4 {print $4}')
    CPU_USAGE=$(echo "100 - $(mpstat | tail -n 1 | awk '{print $NF}')" | bc | sed 's/^\./0./')
    RX_BYTES=$(ifconfig eth | grep "RX bytes" | head -1 | awk '{print $2}' | cut -d : -f 2)
    TX_BYTES=$(ifconfig eth | grep "RX bytes" | head -1 | awk '{print $6}' | cut -d : -f 2)

    DATA="$(sed -e "s/SERIES_NAME/${SERIES_NAME}/" \
                -e "s/DISK_SIZE/${DISK_SIZE}/" \
                -e "s/DISK_USED/${DISK_USED}/" \
                -e "s/DISK_FREE/${DISK_FREE}/" \
                -e "s/DISK_PERCENTAGE/${DISK_PERCENTAGE}/" \
                -e "s/MEM_SIZE/${MEM_SIZE}/" \
                -e "s/MEM_USED/${MEM_USED}/" \
                -e "s/MEM_FREE/${MEM_FREE}/" \
                -e "s/SWAP_SIZE/${SWAP_SIZE}/" \
                -e "s/SWAP_USED/${SWAP_USED}/" \
                -e "s/SWAP_FREE/${SWAP_FREE}/" \
                -e "s/CPU_USAGE/${CPU_USAGE}/" \
                -e "s/RX_BYTES/${RX_BYTES}/" \
                -e "s/TX_BYTES/${TX_BYTES}/" \
                metrics.template )"
    POST="curl -k -X POST -d '${DATA}' '${POSTURL}'"
    echo "${POST}"
    eval ${POST}
    echo "=> Next metrics collecting will be started in ${COLLECT_PERIOD} seconds"
    sleep ${COLLECT_PERIOD}
done
