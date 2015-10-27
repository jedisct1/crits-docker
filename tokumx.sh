#! /bin/sh

set -e

mkdir -p /data/tokumx
chown tokumx:tokumx /data/tokumx 2> /dev/null || true

exec setuser tokumx /opt/tokumx/bin/mongod --dbpath=/data/tokumx --syslog --quiet
