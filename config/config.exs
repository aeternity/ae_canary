# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

git_sha = System.cmd("git", ["rev-parse", "HEAD"]) |> elem(0) |> String.trim()

config :ae_canary,
  ecto_repos: [AeCanary.Repo],
  node_url: "https://mainnet.aeternity.io/",
  site_address: "localhost",
  build: git_sha

# Configures the endpoint
config :ae_canary, AeCanaryWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "h1gZ7OoCUukaas6AjTwLIjSCUrdkQe5l34vHFDnqxf6mlSZD5/j7NfsJcs4NBsYc",
  render_errors: [view: AeCanaryWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: AeCanary.PubSub,
  live_view: [signing_salt: "yJTwaNu9"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ae_canary, AeCanaryWeb.Accounts.Guardian,
  issuer: "AeCanary",
  secret_key: "ZxjSaBGLIU5qGLeVDaBVIe8yXxTO0+rKs/NNuGyA/Fz97oviHxkfg2/hVe8bUO8i"

config :ae_canary, AeCanary.Mdw.Cache.Service.Exchange,
  stats_interval_in_days: 40,
  show_alerts_interval_in_days: 10,
  has_transactions_in_the_past_days_interval: 7,
  suspicious_deposits_threshold: 500_000,
  iqr_use_positive_exposure_only: true,
  iqr_lower_boundary_multiplier: 1.5,
  iqr_upper_boundary_multiplier: 3

config :ae_canary, AeCanary.ForkMonitor,
  fork_monitor_http_client: HTTPoison,
  max_sync_depth: 50_000,
  active_backfill: true

config :ae_canary, AeCanary.Mdw.Cache.Service.IdleDetector,
  alert_idle_minutes: 40,
  min_block_life_seconds: 30

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
