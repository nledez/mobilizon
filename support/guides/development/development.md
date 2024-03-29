# Development
Clone the repo, and start the project through Docker. You'll need both Docker and Docker-Compose.
```bash
git clone https://framagit.org/framasoft/mobilizon && cd mobilizon
make
```
## Manual

  * Install dependencies:
    * Elixir (and Erlang) by following the instructions at [https://elixir-lang.github.io/install.html](https://elixir-lang.github.io/install.html)
    * [PostgreSQL]() with PostGIS
    * Install NodeJS (we guarantee support for the latest LTS and later) ![](https://img.shields.io/badge/node-%3E%3D%2010.0+-brightgreen.svg)
  * Start services:
    * Start postgres
  * Setup services:
    * Make sure the postgis extension is installed on your system.
    * Create a postgres user with database creation capabilities, using the
      following: `createuser -d -P mobilizon` and set `mobilizon` as the password.
  * Install packages
    * Fetch backend Elixir dependencies with `mix deps.get`.
    * Go into the `cd js` directory, `yarn install` and then back `cd ../`
  * Setup
    * Create your database with `mix ecto.create`.
    * Create the postgis extension on the database with a postgres user that has
      superuser capabilities: `psql mobilizon_dev`

      ``` create extension if not exists postgis; ```

    * Run migrations: `mix ecto.migrate`.
  * Start Phoenix endpoint with `mix phx.server`. The client development server will also automatically be launched and will reload on file change.

Now you can visit [`localhost:4000`](http://localhost:4000) in your browser
and see the website (server *and* client) in action.

## Docker
You need to install the latest supported [Docker](https://docs.docker.com/install/#supported-platforms) and [Docker-Compose](https://docs.docker.com/compose/install/) before using the Docker way of installing Mobilizon.

Just run :
```bash
make start
```
to build and launch a database container and an API container running on localhost.
