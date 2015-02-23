# Field Papers

## Helping

If you'd like to help out (thanks!), checking out [this
overview](https://github.com/fieldpapers/fieldpapers).

## Development

[![Build Status](https://travis-ci.org/fieldpapers/fp-web.svg?branch=master)](https://travis-ci.org/fieldpapers/fp-web)

### Using fig

[`fig`](http://www.fig.sh/) is a [Docker](http://www.docker.com/)-based tool for
orchestrating development environments. Rather than using `foreman` to manage
multiple processes locally, `fig` runs each component process in a separate
container, built up from local `Dockerfile`s or from remote repositories.

Keeping your local development environment clean does come at a slight cost, at
least on a Mac. In order to facilitate development, `fig` mounts your local
directory as a volume in the container. Since the container is actually running
in a VM, shenanigans are required to make it transparent and (currently)
results in dramatically decreased performance, at least when starting Rails and
running the asset pipeline on-demand.

(At least that's my current theory; it's also possible that initializing Rails
is stalling as a result of some sort of network misconfiguration in the
container.)

Besides reducing chaos, using `fig` has the benefit of producing and
maintaining Docker-based configurations that can be used in a production
environment (potentially with minor modifications).

On OS X, install `boot2docker` and `fig` and start them up. If images do not
exist, `fig` will create them the first time they're needed.

```bash
brew install boot2docker fig

boot2docker init         # create the Docker host if necessary
boot2docker up           # start the Docker host
$(boot2docker shellinit) # set the necessary Docker environment vars

fig up                   # start all services
```

The app will now be running on port 3000 on the Docker host. `boot2docker ip`
will show you the Docker host's IP, or you can do this:

```bash
open http://$(boot2docker ip):3000/
```

To rebuild, use `fig build`. This is typically only necessary when
modifications are made to the `Dockerfile`; additions to the `Gemfile` can be
applied by running:

```bash
fig run web bundle install --path vendor/bundle
```

NOTE: If you later decide to take the "running locally" approach, you'll need
to delete `vendor/bundle`, as it contains Linux-specific binaries linked to
versions of libraries present in the Docker image.

### Running Locally

Given the observed performance problems, it may make more sense to run the
application locally (you can still use `fig` to run supplementary services like
MySQL, etc.).

On OS X, you'll want use `rbenv` (and `ruby-build`) in order to isolate the
version of Ruby used here (and to prevent it from conflicting with other
projects). `bundler` is similarly used to localize gem dependencies.

[`direnv`](https://github.com/zimbatm/direnv) is a handy way to set
project-specific environment variables (such as `PATH` or `DATABASE_URL`).
A default `.envrc` has been provided that adds `bin/` to your `PATH`
(`$(pwd)/bin`, technically, to prevent abuse) so that bundler binstubs can be
used. It's opt-in, so you'll need to enable it with `direnv allow .`.

```bash
brew install rbenv ruby-build direnv

eval "$(rbenv init -)"     # initialize rbenv
eval "$(direnv hook bash)" # initialize direnv
rbenv install $(< .ruby-version) # install the desired ruby version

gem install bundler        # install bundler using rbenv-installed ruby

bundle install --path vendor/bundle # install dependencies

direnv allow .             # whitelist the local .envrc

rails server # start the app
```

The app will now be running on [localhost:3000](http://localhost:3000/).

You'll probably want to add the following to the end of your `.bash_profile`
(or equivalent):

```bash
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi`
eval "$(direnv hook bash)"
```

When updating, the following should be sufficient to sync your working copy:

```bash
bundle
rake db:migrate RAILS_ENV=development
```

There are probably additional Homebrew dependencies I'm missing because they
were already installed.

NOTE: If you later decide to use `fig`, you'll need to delete `vendor/bundle`
first.

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
pip install transifex-client
```

To see the current translation status:

```bash
tx status
```

To pull pending translations:

```bash
tx pull -a
```

To initialize a new language:

```bash
tx set -r fieldpapers.fp-web-global -l es config/locales/es.yml
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
