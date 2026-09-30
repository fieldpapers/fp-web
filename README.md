# Field Papers (fp-web)

This is the web application behind [fieldpapers.org](https://fieldpapers.org), a pen-and-paper workflow for mapping with OpenStreetMap. Users can print out a paper atlas, mark it up in the field, and the scan or photograph it and upload the result, which will be automatically georeferenced so it can be used as a basemap to trace from or reference in OpenStreetMap editing software like iD or JOSM.

See the [Field Papers organization page](https://github.com/fieldpapers) for more about the project and useful links for reporting a bug, asking for help, or ways to get involved.

## Overview

fp-web is a Ruby on Rails app. It lets users create _atlases_ (printable maps) and upload _snapshots_ (scans or photos of their printouts with handwritten annotations on them), and handles other details like login.Rendering PDF maps and georeferencing uploaded images are delegated to other services:

- [fp-tasks](https://github.com/fieldpapers/fp-tasks) renders atlas pages to PDF, merges them, and georeferences uploaded snapshots.
- [fp-tiler](https://github.com/fieldpapers/fp-tiler) serves map tiles created from those georeferenced uploads.

When an atlas or snapshot needs processing, fp-web sends fp-tasks a request containing a callback URL; fp-tasks does the work and reports progress and results back to that URL. fp-tasks must therefore be able to reach fp-web at its configured `BASE_URL`.

For development setup, see [CONTRIBUTING.md](./CONTRIBUTING.md).

## Running an Instance

[fieldpapers.org](https://fieldpapers.org/) is the only public deployment, but the application can be run independently. An instance requires:

- Postgres (fieldpapers.org runs version 18)
- An [fp-tasks](https://github.com/fieldpapers/fp-tasks) instance
- An [fp-tiler](https://github.com/fieldpapers/fp-tiler) deployment, for displaying snapshots on the map
- File storage for uploaded snapshots: either an S3 bucket, or local disk served over HTTP
- AWS SES, for account confirmation and password reset emails

### Container Image

fp-web is published as a container image at `ghcr.io/fieldpapers/fp-web`; new image versions are published automatically on each commit to `main`, and you can pin a specific image by its commit hash or version number. Running the application from this container is the easiest way to deploy, since the image includes a compatible version of Ruby and all of the necessary gems.

### Database setup

To initialize an empty database, run:

```bash
bin/rails db:schema:load
```

When upgrading to a newer image, apply any new migrations. Migrations are not run automatically on startup.

```bash
bin/rails db:migrate
```

Both commands can be run in a one-off container from the same image, with the same environment variables as the web server.

## Configuration

All configuration is read from environment variables. Most have defaults suited to fieldpapers.org, which other deployments must override.

Two variables are required in production:

- `SECRET_KEY_BASE`: secret used to sign sessions and cookies. Generate one with `bin/rails secret`.
- `DATABASE_URL`: Postgres connection URL, e.g. `postgres://user:password@host:5432/fieldpapers`. If set, it overrides `config/database.yml` for whichever environment is running, including `test`, so only production should set it.

The following variables configure where the application and its sibling services are reachable:

- `BASE_URL`: public URL of this application, used in generated links and in callback URLs sent to fp-tasks (default `https://fieldpapers.org`)
- `URL_HOST`: host name used for links in emails, in production only (default `fieldpapers.org`)
- `TASK_BASE_URL`: base URL of the fp-tasks service (default `https://tasks.fieldpapers.org`)
- `TILE_BASE_URL`: base URL of the fp-tiler service (default `https://tiles.fieldpapers.org`)
- `OSM_BASE_URL`: OpenStreetMap instance used for "edit in OSM" links (default `https://www.openstreetmap.org`)

Uploaded snapshots are stored either in S3 or on local disk. The AWS credentials are also used for sending email through SES.

- `PERSIST`: where to store uploaded snapshots, `s3` or `local` (default `s3`)
- `S3_BUCKET_NAME`: S3 bucket for file storage (default `files.fieldpapers.org`)
- `AWS_REGION`: AWS region for S3 and SES (default `us-east-1`)
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`: AWS credentials with access to the S3 bucket and SES
- `STATIC_PATH`: directory that locally persisted files are written to (default `./public`)
- `STATIC_URI_PREFIX`: URL prefix under which locally persisted files are served (default the value of `BASE_URL`)

Account confirmation and password reset emails are configured with:

- `MAIL_ORIGIN`: from address for account emails (default `help@fieldpapers.org`)
- `MAIL_SOURCE_ARN`: SES source identity ARN, sent with each message if set
- `DISABLE_LOGIN_CONFIRMATIONS`: if `true`, new accounts are usable immediately and no confirmation email is sent (default `false`)

The web server is configured with:

- `PORT`: port Puma listens on (default `3000`)
- `WEB_CONCURRENCY`: number of Puma worker processes (default `2`)
- `MAX_THREADS`: threads per worker, and the size of each worker's database connection pool (default `5`)
- `RAILS_SERVE_STATIC_FILES`: if set to any value, Rails serves precompiled assets and locally persisted files from `public/`; required unless a reverse proxy serves them
- `RAILS_LOG_TO_STDOUT`: if set to any value, logs go to standard output instead of `log/production.log`
- `RAILS_LOG_LEVEL`: log level in production (default `info`)

Miscellaneous other settings:

- `DEFAULT_CENTER`: initial map view for atlas composition, as `<zoom>/<latitude>/<longitude>`
- `ATLAS_COMPLETE_WEBHOOKS`: comma-separated URLs; when an atlas finishes rendering, its JSON representation is `POST`ed to each
- `ATLAS_INDEX_HEADER_TILELAYER`: tile URL template for the map at the top of the atlas list (default `https://tile.openstreetmap.org/{Z}/{X}/{Y}.png`)
- `ANALYTICS_HEAD_FILE`: path to an HTML file (e.g. an analytics snippet) injected into the `<head>` of every page; read once at startup, and ignored if the file does not exist (default `/etc/fieldpapers/analytics.html`)
- `ANALYTICS_HEAD_HTML`: inline alternative to `ANALYTICS_HEAD_FILE`, used only if that file does not exist

## License

This code is available under the ISC license; see the [LICENSE](./LICENSE) file for details.

