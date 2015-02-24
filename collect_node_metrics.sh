#!/bin/bash

source /env.profile

# Disk Metrics
MSG="$(df -mT /var/lib/docker 2>&1)"
DISK_SIZE=$(echo "${MSG}" | tail -n 1 | awk '{print $3}')
DISK_USED=$(echo "${MSG}" | tail -n 1 | awk '{print $4}')
DISK_FREE=$(echo -mT "${MSG}" | tail -n 1 | awk '{print $5}')
DISK_PERCENTAGE=$(echo "${MSG}" | tail -n 1 | awk '{print $6}'| rev | cut -c 2- | rev )

# Mem, CPU Metrics
MSG="$(free -m)"
MEM_SIZE=$(echo "${MSG}" | awk 'NR==2 {print $2}')
MEM_USED=$(echo "${MSG}" | awk 'NR==3 {print $3}')
MEM_FREE=$(echo "${MSG}" | awk 'NR==3 {print $4}')
SWAP_SIZE=$(echo "${MSG}" | awk 'NR==4 {print $2}')
SWAP_USED=$(echo "${MSG}" | awk 'NR==4 {print $3}')
SWAP_FREE=$(echo "${MSG}" | awk 'NR==4 {print $4}')
CPU_USAGE=$(echo "100 - $(mpstat 60 1 | tail -n 1 | awk '{print $NF}')" | bc | sed 's/^\./0./')

# Network Metrics
RX_BYTES=$(cat /sys/class/net/eth?/statistics/rx_bytes | head -n 1)
TX_BYTES=$(cat /sys/class/net/eth?/statistics/tx_bytes | head -n 1)
RX_BYTES="${RX_BYTES:-"0"}"
TX_BYTES="${TX_BYTES:-"0"}"

DATA="$(sed -e "s/DISK_SIZE/${DISK_SIZE}/" \
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
            /metrics.template )"
POST="curl -k -X POST -d '${DATA}' '${NODE_METRICS_URL}'"
echo -n "$(date): Sending node metrics to influxdb. "
echo -n "${DATA}"
eval ${POST}
echo ""
