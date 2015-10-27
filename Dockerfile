
FROM jedisct1/phusion-baseimage-latest:15.10
MAINTAINER Frank Denis (@jedisct1)

USER root

RUN apt-get -y install software-properties-common
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 && \
  apt-add-repository -y universe && \
  apt-get -qq update && apt-get install -y --fix-missing \
  apache2 \
  build-essential \
  curl \
  git \
  jed \
  libapache2-mod-wsgi \
  libevent-dev \
  libfuzzy-dev \
  libimage-exiftool-perl \
  libjpeg-dev \
  libldap2-dev \
  libpcap-dev \
  libpcre3-dev \
  libpng-dev \
  libsasl2-dev \
  libssl-dev \
  libtool \
  libxml2-dev \
  libxslt1-dev \
  libyaml-dev \
  libz-dev \
  numactl \
  p7zip-full \
  poppler-utils \
  pyew \
  python-dev \
  python-m2crypto \
  python-pip \
  python-pillow \
  silversearcher-ag \
  ssdeep \
  supervisor \
  swig \
  tcpdump \
  unrar-free \
  upx \
  vim \
  wget \
  zip

RUN groupadd -r crits && \
  useradd -r -g crits -d /opt/crits -s /sbin/nologin -c "Crits" crits && \
  cd /opt && \
  git clone https://github.com/crits/crits.git && \
  cd crits && \
  pip install -r requirements.txt && \
  cd /opt/crits && \
  cp crits/config/database_example.py crits/config/database.py && \
  SC=$(cat /dev/urandom | LC_CTYPE=C tr -dc 'abcdefghijklmnopqrstuvwxyz0123456789!@#%^&*(-_=+)' | fold -w 50 | head -n 1) && \
  SE=$(echo ${SC} | sed -e 's/\\/\\\\/g' | sed -e 's/\//\\\//g' | sed -e 's/&/\\\&/g') && \
  sed -i -e "s/^\(SECRET_KEY = \).*$/\1\'${SE}\'/1" crits/config/database.py

RUN cd /opt && \
  apt-get install -y yara python-yara && \
  git clone https://github.com/crits/crits_services && \
  cd crits_services && \
  rm -fr taxii_service stix_validator_service

RUN ldconfig && \
  apt-get remove -y --purge build-essential libtool && \
  apt-get autoremove -y --purge && \
  apt-get clean -y && \
  rm -rf /tmp/* && \
  rm -rf /var/lib/apt/lists/*

RUN cd /tmp && \
  curl https://www.percona.com/downloads/percona-tokumx/tokumx-enterprise-2.0.2/binary/tarball/tokumx-e-2.0.2-linux-x86_64-main.tar.gz | \
  tar xzvf - && \
  mkdir -p /opt && \
  mv -f tokumx* /opt/tokumx && \
  groupadd -r tokumx && \
  useradd -r -g tokumx -d /opt/tokumx -s /sbin/nologin -c "TokuMX" tokumx

RUN mkdir -p /etc/services/tokumx
ADD tokumx.sh /etc/service/tokumx/run
ADD tokumx-check.sh /etc/service/tokumx/check

ENV PATH /opt/tokumx/bin:$PATH

RUN \
  /etc/init.d/apache2 stop && \
  rm -rf /etc/apache2/sites-available/* && \
  cp /opt/crits/extras/*.conf /etc/apache2 && \
  cp -r /opt/crits/extras/sites-available /etc/apache2 && \
  rm /etc/apache2/sites-enabled/* && \
  ln -f -s /etc/apache2/sites-available/default-ssl /etc/apache2/sites-enabled/default-ssl && \
  mkdir -pv /etc/apache2/conf.d/i && \
  usermod -a -G crits www-data && \
  a2enmod ssl

RUN \
  export "LANG=en_US.UTF-8" && \
  sed -i "/export\ LANG\=C/ s/C/en\_US\.UTF\-8/" /etc/apache2/envvars && \
  sed -i '$ i\\n0 * * * *       root    cd /opt/crits/ && /usr/bin/python manage.py mapreduces\n0 * * * *       root    cd /opt/crits/ && /usr/bin/python manage.py generate_notifications' /etc/crontab && \
  sed -i 's/^CustomLog\ .*/CustomLog\ \/dev\/null\ combined/' /etc/apache2/apache2.conf && \
  sed -i 's/^CustomLog\ .*/CustomLog\ \/dev\/null\ combined/' /etc/apache2/sites-available/default-ssl && \
  sed -i 's/^ErrorLog\ .*/ErrorLog\ \/dev\/null/' /etc/apache2/apache2.conf && \
  sed -i 's/www\-data/crits/' /etc/apache2/envvars && \
  sed -i 's/\ 443/\ 8443/' /etc/apache2/ports.conf && \
  sed -i 's/443/8443/' /etc/apache2/sites-available/default-ssl && \
  sed -i 's/\/data\//\/opt\//' /etc/apache2/sites-available/default-ssl && \
  sed -i 's/\/data\//\/opt\//' /etc/apache2/httpd.conf

RUN mkdir -p /etc/services/apache
ADD apache.sh /etc/service/apache/run

RUN mkdir -p /etc/services/crits
ADD crits.sh /etc/service/crits/run

ENV HOME /opt/crits

RUN mkdir -p /data
VOLUME ["/data"]

EXPOSE 8443

ENTRYPOINT ["/sbin/my_init"]
