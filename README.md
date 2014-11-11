tutum/node-metrics
=========================

**Requires docker version > 1.2.0**

```
    docker run -d \
      -v /var/lib/docker:/var/lib/docker:rw \
      -e INFLUXDB_PORT_8086_TCP_ADDR=172.17.0.17 \
      -e INFLUXDB_PORT_8086_TCP_PORT=8086 \
      --net host \
      -e DB_NAME=nodemetrics \
      -e DB_USER=root \
      -e DB_PASS=root \
      -e COLLECT_PERIOD=60 \
      -e SERIES_NAME=stats \
      tutum/node-metrics
```

**Arguments**

```
    COLLECT_PERIOD                  how many seconds to run the metrics collection script, 60 by default.
    SERIES_NAME                     name of the series in influxdb, "stats" by default
    INFLUXDB_PORT_8086_TCP_ADDR     ip address of influxdb
    INFLUXDB_PORT_8086_TCP_PORT     port number of influxdb
    DB_NAME                         name of the influx database, "nodemetrics" by default
    DB_USER                         user of influxdb, "root" by default
    DB_PASS                         pass of influxdb, "INFLUXDB_ENV_INFLUXDB_INIT_PWD" if specified, "root" by default

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
        -e PRE_CREATE_DB="nodemetrics" \
        -e SSL_SUPPORT=true \
        tutum/influxdb:latest
```
