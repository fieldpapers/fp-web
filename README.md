# Field Papers

[![Translation Status](https://www.transifex.com/projects/p/fieldpapers/resource/www/chart/image_png)](https://www.transifex.com/projects/p/fieldpapers/resource/www/)

## Helping

If you'd like to help out (thanks!), check out [this
overview](https://github.com/fieldpapers/fieldpapers).

## Development

[![Build Status](https://travis-ci.org/fieldpapers/fp-web.svg?branch=master)](https://travis-ci.org/fieldpapers/fp-web)

### Using docker-compose

[compose](https://docs.docker.com/compose/) is
a [Docker](http://www.docker.com/)-based tool for orchestrating development
environments. Rather than using `foreman` to manage multiple processes locally,
`compose` runs each component process in a separate container, built up from
local `Dockerfile`s or from remote repositories.

#### Prerequisites

* A working instance of [Docker](http://www.docker.com/), via
  [boot2docker](http://boot2docker.io/), [docker
  machine](https://docs.docker.com/machine/), or another mechanism
* mDNS, built-in on OS X, via `libnss-mdns` on Linux or [Bonjour Print Services
  fpr Windows](https://support.apple.com/kb/DL999?locale=en_US)
* [Docker compose](https://docs.docker.com/compose/)

#### Configuration

```bash
cp sample.env .env
# provide some AWS credentials, etc.
open -t .env
```

#### Starting

This will fetch and build images as appropriate. If it doesn't work the first
time (usually when building an image), try it again.

```bash
docker-compose up
```

The app will now be running on port 3000 on the Docker host, conveniently
announcing itself as `fieldpapers.local`. Thus,
`http://fieldpapers.local:3000/`.

To see logs for other processes (web will display), run this in another window/tab:

```bash
docker-compose logs
```

After you make changes to the `Dockerfile` to add system dependencies, you'll
need to run `docker-compose build` in order to recreate the base `web` image.
If you've just made chanegs to `Gemfile`, run `docker-compose run web bundle`.

If this is the first time you're running this (or have pending migrations),
you'll need to (optionally) load data and run the migrations:

```bash
gzip -dc ../data/fieldpapers.sql.gz | \
  docker run \
  -i \
  --rm \
  --link fpweb_db_1:db \
  mysql \
  mysql -uroot -pfp -h db fieldpapers_development
docker run \
  -it \
  --rm \
  -v $(pwd)/db:/app/db \
  -e DATABASE_URL=mysql2://fieldpapers:fieldpapers@db/fieldpapers_development \
  --link fpweb_db_1:db \
  fpweb_web:latest \
  rake db:migrate
```

### Running Locally

Given the potential complexity of the above, or the need to make changes to the
peripheral services, it may make more sense to run the application locally (you
can still use `docker-compose` to run supplementary services like MySQL, etc.).

On OS X, you'll want use `rbenv` (and `ruby-build`) in order to isolate the
version of Ruby used here (and to prevent it from conflicting with other
projects). `bundler` is similarly used to localize gem dependencies.

[`direnv`](https://github.com/zimbatm/direnv) is a handy way to set
project-specific environment variables (such as `PATH` or `DATABASE_URL`).
A default `.envrc` has been provided that adds `bin/` to your `PATH`
(`$(pwd)/bin`, technically, to prevent abuse) so that bundler binstubs can be
used. It's opt-in, so you'll need to enable it with `direnv allow .`.

Ghostscript is used to merge atlas pages together into a single PDF, so you'll
need that (and `boot2docker` generate individual pages) to generate atlases.

#### OS X

```bash
brew install rbenv ruby-build direnv ghostscript boot2docker

boot2docker init         # create the Docker host if necessary
boot2docker up           # start the Docker host
$(boot2docker shellinit) # set the necessary Docker environment vars

eval "$(rbenv init -)"     # initialize rbenv
eval "$(direnv hook bash)" # initialize direnv
rbenv install $(< .ruby-version) # install the desired ruby version

gem install bundler        # install bundler using rbenv-installed ruby

xcode-select --install     # install Xcode command line utilities

# on 10.11, openssl headers aren't easily findable
bundle config build.eventmachine --with-opt-dir=/usr/local/opt/openssl

bundle install -j4 --path vendor/bundle # install dependencies

direnv allow .             # whitelist the local .envrc

echo $DATABASE_URL         # ensure that your environment is prepared

rake db:create             # create a database if one doesn't already exist
rake db:schema:load        # initialize your database

rails server -b 0.0.0.0 # start the app, listening on all interfaces
```

#### Ubuntu

[Install Docker](https://docs.docker.com/installation/ubuntulinux/).

```bash
sudo apt-get install ghostscript git-core curl zlib1g-dev \
  build-essential libssl-dev libreadline-dev libyaml-dev \
  libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev \
  python-software-properties libffi-dev

# install rbenv + ruby-build
git clone git://github.com/sstephenson/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile

git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile

eval "$(direnv hook bash)" # initialize direnv
rbenv install $(< .ruby-version) # install the desired ruby version

gem install bundler        # install bundler using rbenv-installed ruby
gem install foreman

bundle install -j4 --path vendor/bundle # install dependencies

cp sample.env .env
sensible-editor .env

foreman run echo $DATABASE_URL # ensure that your environment is prepared

rake db:create             # create a database if one doesn't already exist
rake db:schema:load        # initialize your database

foreman run rails server -b 0.0.0.0 # start the app, listening on all interfaces
```

The app will now be running on [localhost:3000](http://localhost:3000/) and
will also be available as `<you>.local` (which is what should be used for
`BASE_URL`).

You'll probably want to add the following to the end of your `.bash_profile`
(or equivalent):

```bash
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi`
eval "$(direnv hook bash)"
```

If you choose not to use `direnv`, you'll need to ensure that the contents
of `.env` are exported in your environment.

[foreman](https://github.com/ddollar/foreman) is an alternative, in which
case you'll prefix all commands with `foreman run <cmd>` in order to expose
environment variables to them.

Barring that, `export <VAR>=<VAL>` for each pair in each shell instance
you're using.

When updating, the following should be sufficient to sync your working copy:

```bash
bundle
rake db:migrate RAILS_ENV=development
```

There are probably additional Homebrew dependencies I'm missing because they
were already installed.

NOTE: If you later decide to use `fig`, you'll need to delete `vendor/bundle`
first.

### Environment Variables

If using `direnv` or `foreman`, add these to `.env`. Otherwise, ensure that
they are available to the environment in which Rails is running.

* `DATABASE_URL` - development database URL. Probably similar to
  `mysql2://root@localhost/fieldpapers_development`
* `TEST_DATABASE_URL` - test database URL.
* `RDS_DB_NAME` - production database name.
* `RDS_HOSTNAME` - production database hostname.
* `RDS_PASSWORD` - production database password.
* `RDS_PORT` - production database port.
* `RDS_USERNAME` - production database username.
* `MAIL_ORIGIN` - From address to use for automated system emails.
* `MAIL_SOURCE_ARN` - AWS SES mail source identity. (Associated credentials must
  be granted access to send from this)
* `BASE_URL` - Site base URL (Network-accessible, i.e. from a Docker container).
* `S3_BUCKET_NAME` - S3 bucket for file storage. Defaults to
  `dev.files.fieldpapers.org` (development), `test.files.fieldpapers.org`
  (test), and `files.fieldpapers.org` (production).
* `AWS_ACCESS_KEY_ID` - AWS key with read/write access to the configured S3
  bucket(s).
* `AWS_SECRET_ACCESS_KEY` - Corresponding secret.
* `AWS_REGION` - AWS region to use for services.
* `BASE_URL` - Base URL, e.g. `http://fieldpapers.org`.
* `TASK_BASE_URL` - Base URL for the task server (probably an instance of
  [fp-tasks](https://github.com/fieldpapers/fp-tasks)).
* `TILE_BASE_URL` - Base URL for the snapshot tiler (probably an instance of
  [fp-tiler](https://github.com/fieldpapers/fp-tiler)).
* `SENTRY_DSN` - Sentry DSN for exception logging. Optional.
* `MAPZEN_SEARCH_KEY` - A Mapzen Search API key, obtained from
  [mapzen.com/developers](https://mapzen.com/developers).
* `STATIC_PATH` - Path to write static files to. Must be HTTP-accessible.
  Defaults to `:rails_root/public` (to match the `STATIC_URI_PREFIX` default).
* `STATIC_URI_PREFIX` - Prefix to apply to static paths (e.g.
  http://example.org/path) to allow them to resolve. Defaults to `BASE_URL`.

### Running Tests

```bash
rake
```

Alternately, you can use [Guard](https://github.com/guard/guard) to
automatically run tests when related files change:

```bash
guard
```

### Translation and Localization

Install the [Transifex](https://www.transifex.com/) client (`tx`):

```bash
# optionally create a virtualenv
virtualenv venv
source venv/bin/activate

# install Python dependencies
pip install -r requirements.txt
```

To extract strings from the app (and update pending translations):

```bash
rake gettext:find
```

To see the current translation status:

```bash
tx status
```

To push updated strings:

```bash
tx push -s
```

While it's possible to push updated translations, don't; Transifex is the
source of truth for non-English strings.

To pull pending translations:

```bash
tx pull -af
```

To initialize a new language:

```bash
locale=es
mkdir -p locale/${locale}
cp locale/en/* locale/${locale}/
tx set -r fieldpapers.www -l ${locale} locale/${locale}/app.po
```

You'll also need to add the new locales to
`config/initializers/fast_gettext.rb` and to the footer
(`app/views/shared/_footer.html.erb`).

### Heroku Deployment

Due to the presence of both `Gemfile` and `requirements.txt`, Heroku reports
the ability to build this app using both the Ruby and Python buildpacks. The
current [buildpack detection
order](https://devcenter.heroku.com/articles/buildpacks#buildpack-detect-order)
puts Ruby first, but explicit is better than implicit, so you can force the
Ruby buildpack to be used:

```bash
heroku buildpack:set https://github.com/heroku/heroku-buildpack-ruby
```

### Data

To bootstrap a database for development or on a new instance, run:

```bash
rake db:create db:schema:load
```

By default, it will create a `fieldpapers_development` (and `fieldpapers_test`)
database on a local MySQL instance. To override this, set `DATABASE_URL` (in
your environment, either directly or via `.env`), e.g.:

```bash
DATABASE_URL=mysql2://vagrant@somewhere/fieldpapers_development
```

To migrate an existing Field Papers database, first back it up. Then, set
`DATABASE_URL` to point to it and run (with an appropriate `RAILS_ENV` if
needed):

```bash
rake db:migrate
```

This will produce a database schema that is no longer compatible with the PHP
version. Part of the migration involves cleaning up encoding errors (UTF-8 text
stored as latin1 in UTF-8 columns)--your database may include some invalid
characters, causing the migration to fail. To work-around that, identify the
affected rows and clear their values before retrying the migration.


### AWS Deployment

The Rails `production` environment is set up to allow a "quick start"
deployment on Amazon Web Services using the [`aws-quick-start.py`
script](https://github.com/fieldpapers/fieldpapers/blob/master/aws-quick-start/aws-quick-start.py)
in the
[`fieldpapers/fieldpapers` repository](https://github.com/fieldpapers/fieldpapers).
See the documentation
[here](https://github.com/fieldpapers/fieldpapers/tree/master/aws-quick-start)
details.

A couple of things to note about this production environment:

 * The database configuration (in `config/database.yaml`) is taken
   from a set of `RDS_*` environment variables which are set up
   automatically by AWS within the Docker container where the Rails
   web app runs.  The AWS Relational Database Service (RDS) database
   is set up automatically by the `aws-quick-start.py` script.

 * Access to AWS resources (the S3 bucket used to store atlas pages
   and snapshots, the database, the SES mail service) is managed using
   AWS Identity and Access Management (IAM) roles, policies and
   instance profiles.

 * Obviously the relevant IAM roles, policies and instance profiles
   have to exist with the appropriate permissions.  The easiest (and
   only recommended) way to do this is to use the `aws-quick-start.py`
   script to set everything up.  It's kind of complicated and there
   are no guarantees that it will work if you try to do it by hand...

 * No AWS credentials appear anywhere in the code and no credentials
   are loaded from environment variables (such as `AWS_ACCESS_KEY_ID`
   or `AWS_SECRET_ACCESS_KEY`) when running on an EC2 instance;
   instead, temporary AWS credentials are made available by the
   infrastructure on the EC2 instance and are accessed via the
   instance metadata (the Ruby AWS SDK deals with this transparently).

 * There are some cases where extra authentication information is
   required to perform AWS actions from within an EC2 instance.  In
   particular, a session token is needed to validate temporary AWS
   credentials (a case handled transparently by the AWS Ruby SDK), and
   a "source ARN" is required for sending email (which needs to be
   handled explicitly).  This source ARN is needed to associate the
   EC2 instance with a mail identity policy so that the web app can
   send email using the AWS SES email service.


#### Extra environment variables

These are all set up by the `aws-quick-start.py` script, but are
documented here for reference.  They should *not* need to be set
explicitly!

* `MAIL_ORIGIN` - the originating email address used for sending
  account confirmation, password reset, etc. emails.
* `MAIL_SOURCE_ARN` - AWS resource identifier used to associate EC2
   instance with a mail identity policy, allowing email to be sent
   from within an EC2 instance using the AWS Simple Email Service
   (SES).
