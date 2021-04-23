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

## User accounts

The service is intended to be ran locally by a limited amount of users. This
is to prevent it from being compromised by a third party. `AeCanary` protects
your own interest and you should run it yourself, please don't rely on third
parties. With this in mind, some improtant functionality is protected behind
layers of authentication and authorization.

### Account roles

There are the following account roles:

#### Unauthenticated users

They have only a limited access to the public functionality.


#### Regular users

Regular users have access to private functionality but with regards of account
management, they can modify only their account.

#### Admin users

Admins have access to all the functionality available to regular users but
they can also create, modify and delete existing accounts.

#### Archived users

Those were users that were forbidden from logging in the system.

This is the highest level

### Default accounts

By default the `priv/repo/seeds.exs` inserts the following *test* accounts:

| email | password | role |
|---|---|---|
| admin | admin | admin |
| user | user | user |
| archived | archived | archived |

As you can see, their email addressed are not valid and should be used in
tests only. Please do not use them in production.

# TODO

- [x] Account management: accounts can be created, updated and deleted. Only
  admins can create accounts. Every account can change their name, email
  address and password.

- [ ] Pool support for fetching data from MDW. MDW address is configurable.

- [ ] Introduce tainted addresses. Track their balances on a regular basis.

- [ ] Introduce exchange accounts. Track their exposure on a regular basis.

- [ ] Revisit the index page and dashboard

- [ ] Log events.

- [ ] Send alerts via email/Telegram bot.
