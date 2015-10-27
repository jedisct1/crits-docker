#! /bin/sh

set -e

sv start tokumx

cd /opt/crits

if [ ! -s /data/tokumx/crits-ok ]; then
  echo 'CRITs is initializing...'
  python /opt/crits/manage.py create_default_collections
  python /opt/crits/manage.py setconfig allowed_hosts localhost
  echo
  echo '***********************************************************************'
  python /opt/crits/manage.py users -a -A \
    -e 'admin@crits.local' -f 'Admin' -l 'Admin' -o 'Admin' -u admin
  echo '***********************************************************************'
  date > /data/tokumx/crits-ok
fi

chown -R crits:crits /opt/crits/logs
exec setuser crits python manage.py runserver -v0 0.0.0.0:8080
