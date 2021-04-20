# AeCanary

`AeCanary` tracks suspicious accounts. It allows the user to mark accounts
suspicious and then AeCanary would track all accounts it sent tokens to. This
can be used for tracing stolen tokens.

This service also tracks current exposure of different exchanges: what is the
current amount to be lost if there is a 51% attack now. This can be used by
exchanges for an early alarm.


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


## Installation
To start the server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`; if this is not a
    fresh installation you don't want to delete old DB records and you want to
    apply new DB migrations using `mix ecto.migrate`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server` or ` iex -S mix phx.server`
    if you prefer console mode

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

