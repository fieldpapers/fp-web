# Troubleshooting

## Error: client and server don't have same version (client : 1.17, server: 1.14)

Your `docker` client and server versions differ (use `docker version` to see
what versions are in use). This will upgrade both on OS X:

```bash
brew update && \
  brew upgrade docker boot2docker && \
  boot2docker upgrade && \
  boot2docker init
```

## Post http:///var/run/docker.sock/v1.18/containers/create: dial unix /var/run/docker.sock: no such file or directory. Are you trying to connect to a TLS-enabled daemon without TLS?

The `docker` client can't connect to an appropriate server. `$(boot2docker
shellinit` will set relevant environment variables. If these (`DOCKER_HOST`
etc.) are present, the `boot2docker` VM may not be running.

## The snapshot processor can't access the API

First, check to see that the IP/hostname present in the PDF corresponds to your
development instance (i.e. isn't `fieldpapers.org`; this can be configured by
setting `API_BASE_URL`). Second, ensure that your docker containers can access
it using that name. Using `<hostname>.local` is a convenient way to do so and
to survive DHCP renewals.

## I have a `.env` but my environment doesn’t reflect it

Assuming you're also using `direnv`, the easiest way to do this is to exit the
directory and reenter: `cd ..; cd -`.

# ActiveRecord::AdapterNotSpecified: database configuration does not specify adapter

`DATABASE_URL` probably isn't set. It should look like
`mysql2://root@localhost/fieldpapers_development`.

# `rails` won't start after complaining about missing gems

First, make sure your gems are up-to-date by running `bundle`. If they are (and
are installed globally), try removing `.bundle/config`, as it's likely
preventing system gems from being loaded correctly. This is most likely to
happen when running Field Papers with Docker.
