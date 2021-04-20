# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :ae_canary,
  ecto_repos: [AeCanary.Repo]

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

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"