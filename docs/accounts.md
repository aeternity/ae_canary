# User accounts

The service is intended to be ran locally by a limited amount of users. This
is to prevent it from being compromised by a third party. `AeCanary` protects
your own interest and you should run it yourself, please don't rely on third
parties. With this in mind, the improtant functionality is protected behind
layers of authentication and authorization.

## Account roles

There are the following account roles:

### Unauthenticated users

They have only a limited access to the public functionality.

### Regular users

Regular users have access to private functionality but with regards of account
management, they can modify only their account.

### Admin users

Admins have access to all the functionality available to regular users but
they can also create, modify and delete existing accounts. They also can
modify settings and addresses to be monitored.

This is the highest level

### Archived users

Those were users that were forbidden from logging in the system.

### Default accounts

By default the `priv/repo/seeds.exs` inserts the following *test* accounts:

| email | password | role |
|---|---|---|
| admin | admin | admin |
| user | user | user |
| archived | archived | archived |

As you can see, their email addressed are not valid and should be used in
tests only. Please do not use them in production. You are strongly advised to
delete them once you create some admin accounts.

