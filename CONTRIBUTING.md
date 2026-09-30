# Contributing to fp-web

Contributions to Field Papers are welcome. This document covers setting up a development environment for fp-web. For an overview of the application and available config variables, see the [README](./README.md). The [Field Papers organization page](https://github.com/fieldpapers) has other useful links for those interested in getting involved.

## Development Setup

### With Podman or Docker Compose

`docker-compose.yml` runs the application with a Postgres database and a local instance of [fp-tasks](https://github.com/fieldpapers/fp-tasks). It works with either `podman compose` or `docker compose`.

1. Clone fp-tasks next to this repository, at `../fp-tasks`.

2. Build and start the services:

   ```bash
   podman compose up --build
   ```

3. On first run, create and load the development and test databases:

   ```bash
   podman compose exec web bin/rails db:create db:schema:load
   ```

The application is then available at <http://localhost:3000>. The `app`, `config`, `db`, `lib`, `locale`, `public`, and `test` directories are mounted into the container, so code changes take effect without rebuilding. Changes to the `Gemfile` or `Dockerfile` require `podman compose build web`.

`docker-compose.yml` sets the configuration needed for development: uploads are stored on local disk, email confirmation is disabled, and the database connection is preconfigured. To add or override environment variables (for example, AWS credentials to test S3 or email), put them in a `.env` file, which is passed to both the `web` and `tasks` services if it exists.

The compose setup has some limitations:

- `BASE_URL` is `http://web:3000`, so that fp-tasks can reach fp-web's callback URLs within the compose network. Links built from `BASE_URL`, such as those printed on rendered PDFs, don't resolve from the host.
- fp-tiler can't run locally (v2 runs only on AWS Lambda), so tiles for locally uploaded snapshots don't render. Maps use the production tile server at `https://tiles.fieldpapers.org`.
- Rendered atlas PDFs are written to `public/atlases/`.

### Without Containers

Running fp-web directly requires:

- Ruby, at the version in `.ruby-version` (with [mise](https://mise.jdx.dev), run `mise install`)
- A running Postgres server

Dependencies and databases are then set up with:

```bash
bundle install
bin/rails db:create db:schema:load
bin/rails server
```

By default, Rails connects to the local Postgres server over its Unix socket as the current user. To connect elsewhere, set the standard libpq variables (`PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`). Don't set `DATABASE_URL` in development: it takes precedence over `config/database.yml` for whichever environment is running, including `test`.

Rendering atlases also requires an fp-tasks instance at `TASK_BASE_URL` that can reach this application at `BASE_URL`.

## Tests

The test suite uses Minitest:

```bash
# if using docker/podman
podman compose exec web bin/rails test

# if running without containers
bin/rails test
```

`bin/rails test` always runs in the `test` environment, against the `fieldpapers_test` database. [Guard](https://github.com/guard/guard) (`bundle exec guard`) can rerun tests automatically as files change.

## Database Changes

`db/schema.rb` is the source of truth for the database schema; new databases are created from it with `db:schema:load`. To change the schema, add a migration with `bin/rails generate migration`, apply it with `bin/rails db:migrate`, and commit both the migration and the updated `db/schema.rb`.

## Translations

User-facing strings are translated with [gettext](https://github.com/grosser/gettext_i18n_rails). To mark a string for translation, wrap it in `_()`. In an ERB template,

```erb
<% content_for :title, "Atlas - Field Papers" %>
```

becomes

```erb
<% content_for :title, _("Atlas - Field Papers") %>
```

and in JavaScript within an ERB template,

```js
window.alert("Hello Field Papers!")
```

becomes

```js
window.alert(_('<%= escape_javascript _("Hello Field Papers!") %>'))
```

To extract marked strings into `locale/*/app.po`:

```bash
bin/rake gettext:find
```

Translations are managed on Transifex, which is the source of truth for all non-English strings. Syncing with it requires the [Transifex CLI](https://developers.transifex.com/docs/cli) (`tx`) and project maintainer credentials:

```bash
tx status      # show translation status
tx push -s     # upload updated English source strings
tx pull -af    # download translations
```

Don't push translations with `tx push -t`; edit them on Transifex instead.

To add a new language, first add it to the Transifex project, then pull it (Korean in this example), which creates `locale/ko/app.po`:

```bash
tx pull -f -l ko
```

Then add the locale to `FastGettext.default_available_locales` in `config/initializers/fast_gettext.rb` and to the language list in `app/views/shared/_footer.html.erb`.
