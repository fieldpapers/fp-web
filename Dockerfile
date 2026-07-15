FROM ruby:3.1.3-slim AS base

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      git \
      nodejs \
      default-libmysqlclient-dev \
      libpq-dev \
      zlib1g-dev \
      libssl-dev \
      shared-mime-info && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
ENV PATH=/app/bin:$PATH


FROM base AS development

COPY Gemfile Gemfile.lock ./
RUN bundle install -j4

COPY . .

CMD ["sh", "-c", "rm -f tmp/pids/server.pid && bundle exec rails server -b 0.0.0.0"]


FROM base AS production

ENV RAILS_ENV=production \
    RACK_ENV=production \
    BUNDLE_WITHOUT="development:test"

COPY Gemfile Gemfile.lock ./
RUN bundle install -j4

COPY . .

# set dummy values for some config vars here (otherwise Rails will error)
RUN SECRET_KEY_BASE=placeholder \
    DATABASE_URL=postgres://user:pass@localhost:5432/db \
    bundle exec rails assets:precompile

RUN useradd --create-home app && chown -R app:app /app
USER app

EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
