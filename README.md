# AeCanary

`AeCanary` is a tool that tracks suspicious behaviour and tainted accounts. It
allows the user to mark accounts suspicious and then AeCanary would track all
accounts it sent tokens to. This can be used for tracing stolen tokens.

We define a metric - exposure - the difference between deposit and withdrawal
amounts at a given moment for a specific exchange. AeCanary tracks the
exposure of addresses: what is the current amount to be lost if there is a 51%
attack now. This can be used by exchanges in order to rise an early alarm for
a potential attack.

## How to start

Possibly the easiest way to run the service is in a container, there is a
description [here](/docs/docker.md). If you prefer installing from source
code, please check the description [here](/docs/installation.md).

# TODO

- [x] Account management: accounts can be created, updated and deleted. Only
  admins can create accounts. Every account can change their name, email
  address and password.

- [x] Pool support for fetching data from MDW. MDW address is configurable.

- [ ] Introduce tainted addresses. Track their balances on a regular basis.

- [x] Introduce exchange accounts. Track their exposure on a regular basis.

- [ ] Revisit the index page and dashboard

- [ ] Log events.

- [ ] Send alerts via email/Telegram bot.

- [x] Add Docker support.

