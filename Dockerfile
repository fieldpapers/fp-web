FROM ubuntu:14.04

# Initialization

ENV DEBIAN_FRONTEND noninteractive

RUN \
  apt-get update && \
  apt-get upgrade -y && \
  apt-get clean

# Core dependencies

RUN \
  apt-get install -y software-properties-common curl git build-essential && \
  apt-get clean

# System dependencies

RUN \
  apt-add-repository ppa:brightbox/ruby-ng && \
  apt-get update && \
  apt-get install -y ruby2.1 ruby2.1-dev zlib1g-dev && \
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
# ADD . /app/

RUN bundle install --path vendor/bundle

VOLUME ["/app"]
