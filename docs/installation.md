# Installation from source

This document will guide you through the installation process of the service.

## Prerequisites

### Elixir

`AeCanary` had been developed and tested using Elixir v1.11. You can install
Elixir locally following [the official
guide](https://elixir-lang.org/install.html).

### PostgreSQL
`AeCanary` uses a PostgreSQL database to persist data. The server manages all
DB migrations for you but it relies on having a certain DB account and
a database had already been made for it. Those are configurable according to
the different builds: dev, test and prod in the approriate
[configs](config/).

For dev environment that would be:

* **user**: `ae_canary` with a CREATEDB priviliges; If you don't want to allow
  it, you can create a DB `ae_canary_dev` and grant it all permissions. Note
  in this case `mix ecto.drop` will not work.

* **password**: `canary_pass`

You can use the `create_db_user.sql` to create that PostgreSQL user for you.

For production, please check [prod.secret.exs](config/prod.secret.exs).

### Node.js

The front-end depends on having `node` and `npm` locally.

## Dev environment

After you've cloned the repo, you need to:

  * `mix deps.get`
  * `mix deps.compile`
  * `cd assets && npm install`
  * `cd assets && npm run deploy`
  * `mix do compile, phx.digest`
  * Create and migrate your database with `mix ecto.setup`; if this is not a
    fresh installation: you don't want to delete old DB records and you want to
    apply new DB migrations using `mix ecto.migrate`
  * Optional step: if you want to populate your DB with the list of preset
    exchanges, run `mix run priv/repo/exchanges.exs`
  * Start AeCanary with `mix phx.server` or ` iex -S mix phx.server`
    if you prefer console mode

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
Please note that the script creates the database.

## Prod environment

The production environment disables some error messages, limits log messages
for privacy reasons and provides better experience. It also comes with some
expectations for environment variables.

If you want to run your node in a production environment you must start with
```
export MIX_ENV=prod
```

This will inform `mix` to use `./config/prod.exs` and
`./config/prod.secret.exs` for configuring the system.

You will need the following environment variables:

  * POSTGRES_USER - the DB user to be used
  * POSTGRES_PASSWORD - the user password to be used
  * POSTGRES_HOST - the host of the DB
  * POSTGRES_DB - the database name to be created and used
  * GUARDIAN_SECRET_KEY - the secret to be used for producing JWT.
  * SECRET_KEY_BASE - the secret key for the Phoenix server.
  * MDW_URL - the url of the AE Middleware

For more detailed explanation of settings you can check the [settings
document](/docs/settings.md)

## Accounts

After a fresh installation on a new database, there will be some accounts
created so you can try the different account types. You are strongly suggested
to create new accounts and to delete the preset ones. You can read more about
accounts [here](/docs/accounts.md).
