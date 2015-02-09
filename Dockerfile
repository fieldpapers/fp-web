FROM ubuntu:14.04

# Initialization

ENV DEBIAN_FRONTEND noninteractive

RUN \
  apt-get update && \
  apt-get upgrade -y && \
  apt-get clean

# Core dependencies

RUN \
  apt-get install -y software-properties-common apt-transport-https curl build-essential && \
  apt-get clean

# System dependencies

RUN \
  apt-add-repository ppa:brightbox/ruby-ng && \
  add-apt-repository "deb https://deb.nodesource.com/node $(lsb_release -c -s) main" && \
  (curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -) && \
  apt-get update && \
  apt-get install -y nodejs ruby2.1 ruby2.1-dev zlib1g-dev libmysqlclient-dev libssl-dev && \
  apt-get clean

RUN \
  gem install --no-rdoc --no-ri bundler

# Application dependencies

RUN \
  useradd -d /app -m fieldpapers

USER fieldpapers
ENV HOME /app
WORKDIR /app

ADD Gemfile /app/Gemfile

RUN bundle install --path vendor/bundle

ADD . /app/

VOLUME ["/app"]
