#! /bin/sh

sv start tokumx

if [ ! -s /data/ssl/private/crits.plain.key ]; then
  mkdir -p /data/ssl/certs /data/ssl/private && \
  cd /tmp && \
  openssl req -nodes -newkey rsa:4096 -keyout new.cert.key -out new.cert.csr -subj "/CN=CRITs/O=REMnux/C=US" && \
  openssl x509 -in new.cert.csr -out new.cert.cert -req -signkey new.cert.key -days 3656 && \
  mv new.cert.cert /data/ssl/certs/crits.crt && \
  mv new.cert.key  /data/ssl/private/crits.plain.key
fi

ln -sf /data/ssl/certs/crits.crt /etc/ssl/certs/ && \
ln -sf /data/ssl/private/crits.plain.key /etc/ssl/private/

exec apache2ctl -DFOREGROUND

