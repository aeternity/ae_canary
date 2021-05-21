# Settings

## AE Middleware

AeCanary consumes the API of [AE MDW](https://github.com/aeternity/ae_mdw). It
relies on having a MDW service talking to a synced node. If there is any issue
with the MDW or the node it relies on, this would impact the service of
AeCanary as well.

The service is configurable via a setting `MDW_URL`. It should include the
scheme (`http://` or `https://`).

## Secrets

### Guardian secret key

AeCanary uses [Guardian](https://github.com/ueberauth/guardian) for
authentication. It signs JWT tokens and for this it needs a key. It is
specified in `GUARDIAN_SECRET_KEY`. You can generate a sample key with
`openssl` for example, but any string would work.

### Phoenix secret key base

AeCanary is built using [Phoenix framewor](https://www.phoenixframework.org).
It encodes sensitive data via a key. It must be at least 32 characters long.

```
openssl rand -base64 64
```

