use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :ae_canary, AeCanary.Repo,
  username: "ae_canary",
  password: "canary_pass",
  database: "ae_canary_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ae_canary, AeCanaryWeb.Endpoint,
  http: [port: 4002],
  server: false

config :ae_canary, AeCanary.Mdw.Cache.Service,
  startup_delay: 240000

config :ae_canary, :fork_monitor_http_client, AeCanary.MockHTTPChain

# Print only warnings and errors during test
config :logger, level: :warn
