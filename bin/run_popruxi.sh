#!/bin/bash

export POPRUXI_SERVER=${POPRUXI_SERVER:-localhost}
export POPRUXI_SERVERPORT=${POPRUXI_SERVERPORT:-110}
export POPRUXI_LISTENPORT=${POPRUXI_LISTENPORT:-10110}
export POPRUXI_DBFILE=${POPRUXI_DBFILE:-./bin/../var/popruxi.db}
export POPRUXI_LOGDIR=${POPRUXI_LOGDIR:-/var/log/popruxi}

exec ./popruxi.pl \
	--server=${POPRUXI_SERVER} \
	--serverport=${POPRUXI_SERVERPORT} \
	--listenport=${POPRUXI_LISTENPORT} \
	--dbfile=${POPRUXI_DBFILE} \
	--logpath=${POPRUXI_LOGDIR}/popruxi.log \
	--loglevel=debug