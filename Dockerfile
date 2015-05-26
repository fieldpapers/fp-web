FROM ubuntu:14.04

# Initialization

ENV DEBIAN_FRONTEND noninteractive

RUN \
  apt-get update && \
  apt-get upgrade -y && \
  apt-get clean

# Core dependencies

RUN \
  apt-get install -y software-properties-common apt-transport-https curl build-essential lsb-release git avahi-daemon && \
  apt-get clean

RUN \
  sed -i -e 's/#enable-dbus=yes/enable-dbus=no/' /etc/avahi/avahi-daemon.conf && \
  sed -i -e 's/rlimit-nproc=3//' /etc/avahi/avahi-daemon.conf

# System dependencies

RUN \
  apt-add-repository ppa:brightbox/ruby-ng && \
  add-apt-repository "deb https://deb.nodesource.com/node_0.10 $(lsb_release -c -s) main" && \
  (curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -) && \
  apt-get update && \
  apt-get install -y nodejs ruby2.2 ruby2.2-dev zlib1g-dev libmysqlclient-dev libssl-dev && \
  apt-get clean

RUN \
  gem install --no-rdoc --no-ri bundler

# Application dependencies

WORKDIR /app

ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock

RUN bundle

ADD . /app/

ENV PATH /app/bin:$PATH
VOLUME /app/app /app/config /app/db /app/lib /app/locale /app/public /app/test

CMD avahi-daemon -D && rm -f tmp/pids/server.pid && rails server -b 0.0.0.0
