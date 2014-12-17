tutum/node-metrics
=========================

**Requires docker version > 1.2.0**

```
    docker run -d \
      -v /var/lib/docker:/var/lib/docker:rw \
      -e INFLUXDB_PORT_8086_TCP_ADDR=127.0.0.1 \
      -e INFLUXDB_PORT_8086_TCP_PORT=8086 \
      --net host \
      -e DB_NAME=nodemetrics \
      -e DB_USER=root \
      -e DB_PASS=root \
      tutum/node-metrics
```

**Arguments**

```
    INFLUXDB_PORT_8086_TCP_ADDR     ip address of influxdb
    INFLUXDB_PORT_8086_TCP_PORT     port number of influxdb
    DB_NAME                         name of the influx database, "nodemetrics" by default
    DB_USER                         user of influxdb, "root" by default
    DB_PASS                         pass of influxdb, "INFLUXDB_ENV_INFLUXDB_INIT_PWD" if specified, "root" by default
    DATA_CLEAN_SINCE                clean old metrics since "1w"(default: 1 week) ago. Please modify crontab.conf accordingly if you change this value
    INFLUXDB_ENV_INFLUXDB_INIT_PWD      Inherited variable from influxdb, changing default password of influxdb
```

**INFLUXDB DATA SAMPLE**

```
[
    {
        "name": "stats",
        "columns": [
            "disksize",
            "diskused",
            "diskfree",
            "diskpct",
            "memsize",
            "memused",
            "memfree",
            "swapsize",
            "swapused",
            "swapfree",
            "cpuusage",
            "rxbytes",
            "txbytes"
        ],
        "points": [
            37929,
            6411,
            29569,
            18,
            2001,
            899,
            1102,
            2047,
            0,
            2047,
            3.3,
            25253235,
            243566
        ]
    }
]
```

Notice
------
In order to write metrics to local influxdb container, you can start influxdb like this:

```
    docker run -d \
        -p 8084:8084 \
        --name influxdb \
        -e PRE_CREATE_DB="cadvisor; nodemetrics" \
        -e SSL_SUPPORT=true \
        tutum/influxdb:latest
```

Usage
-----
The downsampled data is store in `stats.1m, stats.5m, stats.30m, stats.2h, stats.1d`
