# Settings

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

## Exchanges' exposure

All known exchange addresses are tracked for AE movements. The idea is that
they are the biggest potential victims of a 51% attack. A metric is defined:
exposure. This is the difference between total amount of deposits and the
total amount of withdrawals in a given day. If the exposure is a positive
number - then there were more deposited amounts than withdrawaled ones and the
address would lose tokens if there was a 51% attack on the given day. If the
exposire is a negative one - the address would gain that many tokens in if
there were a rollback on that date. A rapid increase of the exposure of an
address could be an early symptom for a 51% attack. This does not mean there
will be an attack but rather that this address will be vunerable if there were
an attack. If there are a couple of addresses with similar spikes of exposure,
then the risk is higher.

Based on this metric, different alerts can be produced. The alerts are based
on the accumulated data over intervals of days. There are settings to adjust
this according to user's needs. What is more - having those adjustable helps
obfuscate the service: two instances of AeCanary running the same software
with a different settings will yeld different results. Thus a potential
attacker will not know what metrics we are tracking and could not take
advantage of this information. Although all of the settings have default
values, you are strongly encouraged to change them.

### Stats scope

The graphs show data on a daily basis for a certain amount of days back. All
graphs show the same timeframe so they are easy to compare and to spot similar
patterns to different addresses. Any statistical analysis is based on this set
of data for those days, thus this is the most imporant metric. Either too
short or too long frame could lead to sckewed data. You can change it using
`EXCHANGES_STATS_INTERVAL`. The value is the amount of days and the default is
30.


### Alerts interval

There are alerts generated for suspicious events. Those are limited to a
timeframe so past suspicious events are not causing additional noise. There is
no right number here but a rule of the thumb would be: "if you think an
alternative fork could span for maximum of X days, then use X here". The
config variable is `EXCHANGES_ALERTS_INTERVAL`. The value is the amount of
days and the default is 7.

### Shown exchanges on internal dasboard

On the exchanges' exposure page there is a detailed view for all addresses and
their exposures. Alerts are detailed as well. On the internal dashboard,
though, there is a overview regarding alerts and accumulated data for
exchanges. Since this is simply an overview, we do not need to show all
exchanges there and limit only to ones that had a transaction for the past X
days. If there were no transaction there - the exchange is ommited from the
overview graph.
The config variable is `EXCHANGES_HAS_TXS_INTERVAL`. The value is the amount
of days and the default is 7.

### Suspicious deposits

Although transactions with large amounts are not uncommon, they rise some
flags for the risk they bring for the receiving address. Thus AeCanary pays
special attention for those. You can define yourself what a large amount would
be for you using `EXCHANGES_SUSPICIOUS_DEPOSIT_THRESHOLD` setting. This is the
minimum amount in AE tokens for a transaction to have in order to be
considered suspicious. Please note that only deposits to exchanges can be
suspicious and withdrawals are not.

### Statistical analysis

Exchanges keep a relatively steady flow of transactions: both deposits and
withdrawals. This allows us to do a statistical analysis and to spot daily
exposures that are outliers in the data set. Not that this does not mean that
they are a good measure to detect an attack but still can help detrminging
what a reasonable exposure would be, based on the [statistics
scope](#stats-scope).

AeCanary uses an IQR method for detecting outliers. It is a quite
straightforward approach: we define "fences" based on Q3. If a value is higher
than the fence - it is an outlier. The formula is:

```
fence = Q3 + IQR * multiplier

```

AeCanary suppoerts two multipliers defining a lower and upper fences. Crossing
the former is not unexpected and shall not be treated as such. The exposure
going above the latter though is a bigger diviation and it is expected to
happen less frequently.

Those are adjustable as settings, as follows:

* `EXCHANGES_IQR_LOWER_BOUNDARY_MULTILPLIER` with a defalt `1.5`
* `EXCHANGES_IQR_UPPER_BOUNDARY_MULTILPLIER` with a defalt `3`

Again, those define helper fences to determine if a daily exposure was an
outlier. Using this metric only for detecting an attack would yeld more false
positives than detecting actual attacks, so please use with caution.

Additionally some days exchanges experience negative exposures and this is
completely fine. This though can impact AeCanary's analysis. There is a
boolean setting for fine tuning the service - shall negative exposures be
taken into account or shall only positive numbers be used instead. The setting
is called `EXCHANGES_IQR_USE_POSITIVE_EXPOSURE_ONLY` and the default is true.


