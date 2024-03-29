# Install

## Dependencies

Follow the steps of the [dependencies guide](dependencies.html)

## Database

Create the production database and a mobilizon user inside PostgreSQL:

```bash
sudo -u postgres createuser -P mobilizon
sudo -u postgres createdb -O mobilizon mobilizon_prod
```

Then enable extensions Mobilizon needs:

```bash
sudo -u postgres psql -c "CREATE EXTENSION postgis;" mobilizon_prod
sudo -u postgres psql -c "CREATE EXTENSION pg_trgm;" mobilizon_prod
sudo -u postgres psql -c "CREATE EXTENSION unaccent;" mobilizon_prod
```


## Mobilizon user

Create a `mobilizon` user with `/home/mobilizon` home:
```bash
sudo adduser --disabled-login mobilizon
sudo -i -u mobilizon
```

**On FreeBSD**

```bash
sudo pw useradd -n mobilizon -d /home/mobilizon -s /usr/local/bin/bash -m
sudo passwd mobilizon
```

You can now fetch the code with git:
```bash
git clone https://framagit.org/framasoft/mobilizon live && cd live
```

## Configuration

### Backend

Install Elixir dependencies

```bash
mix deps.get
```

Configure your instance with

```bash
mix mobilizon.instance gen
```

This will ask you questions about your instance and generate a `.env.prod` file.

### Migration

Run database migrations: `mix ecto.migrate`. You will have to do this again after most updates.

> If some migrations fail, it probably means you're not using a recent enough version of PostgreSQL,
or that you haven't installed [the required extensions](#database).

### Front-end

Go into the `js/` directory

```bash
cd js
```

and install the Javascript dependencies

```bash
yarn install
```

Finally, build the front-end with
```bash
yarn run build
```

## Services

### Systemd

Copy the `support/systemd/mobilizon.service` to `/etc/systemd/system`.

```bash
sudo cp support/systemd/mobilizon.service /etc/systemd/system/
```

Reload Systemd to detect your new file

```bash
sudo systemctl daemon-reload
```

And enable the service

```bash
systemctl enable --now mobilizon.service
```

It will run Mobilizon and enable startup on boot. You can follow the logs with

```bash
sudo journalctl -fu mobilizon.service
```

The Elixir server runs on port 4000 on the local interface only, so you need to add a reverse-proxy.

## Reverse proxy

### Nginx

Copy the file from `support/nginx/mobilizon.conf` to `/etc/nginx/sites-available`.

```bash
sudo cp support/nginx/mobilizon.conf /etc/nginx/sites-available
```

Then symlink the file into the `/etc/nginx/sites-enabled` directory.

```bash
sudo ln -s /etc/nginx/sites-available/mobilizon.conf /etc/nginx/sites-enabled/
```

Edit the file `/etc/nginx/sites-available` and adapt it to your own configuration.

Test the configuration with `sudo nginx -t` and reload nginx with `systemctl reload nginx`.