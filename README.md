# Field Papers

## Development

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

```bash
brew install rbenv ruby-build

eval "$(rbenv init -)"   # initialize rbenv

gem install bundler      # install bundler using rbenv-installed ruby

bundle install --path vendor/bundle # install dependencies

bundle exec rails server # start the app
```

The app will now be running on [localhost:3000](http://localhost:3000/).

There are probably additional Homebrew dependencies I'm missing because they
were already installed.

NOTE: If you later decide to use `fig`, you'll need to delete `vendor/bundle`
first.

### Data

There is not yet a mechanism for bootstrapping a new database. If you have
a running instance of Field Papers (or access to one), you should point to that
database (in `config/database.yml`; you'll likely need to change the
credentials and the database name) and create the views from `db/mysql.sql`.

After making changes to the views, it's good form to run `bundle exec annotate`
to update comments on affected models. This will run automatically when Rails
manages the database, but in the meantime, it needs to be run by hand to keep
things in sync.
