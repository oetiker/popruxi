#!/bin/bash

export POPRUXI_SERVER=${POPRUXI_SERVER:-localhost}
export POPRUXI_SERVERPORT=${POPRUXI_SERVERPORT:-110}
export POPRUXI_LISTENPORT=${POPRUXI_LISTENPORT:-10110}
export POPRUXI_DBFILE=${POPRUXI_DBFILE:-./bin/../var/popruxi.db}
ENV

exec /opt/oss/popruxi/bin/popruxi.pl \
                  --server=${POPRUXI_SERVER} \
                  --serverport=${POPRUXI_SERVERPORT} \
                  --listenport=${POPRUXI_LISTENPORT} \
                  --dbfile=${POPRUXI_DBFILE}
