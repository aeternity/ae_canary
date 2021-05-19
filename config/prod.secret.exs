# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
use Mix.Config

db_user =
  System.get_env("POSTGRES_USER") ||
    raise """
    environment variable POSTGRES_USER is missing.
    """

db_pass =
  System.get_env("POSTGRES_PASSWORD") ||
    raise """
    environment variable POSTGRES_PASSWORD is missing.
    """

db_host =
  System.get_env("POSTGRES_HOST") ||
    raise """
    environment variable POSTGRES_HOST is missing.
    """

db_db =
  System.get_env("POSTGRES_DB") ||
    raise """
    environment variable POSTGRES_DBis missing.
    """

database_url =
  "ecto://#{db_user}:#{db_pass}@#{db_host}/#{db_db}"

guardian_secret_key =
  System.get_env("GUARDIAN_SECRET_KEY") ||
    raise """
    environment variable GUARDIAN_SECRET_KEY is missing.
    Please run mix guardian.gen.secret
    """

mdw_url =
  System.get_env("MDW_URL") ||
    raise """
    environment variable MDW_URL is missing.
    This is the address of the Aeternity MDW to be used for data fetching
    """

config :ae_canary, AeCanary.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :ae_canary, AeCanaryWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base

config :ae_canary, AeCanary.Accounts.Guardian,
  secret_key: guardian_secret_key 

config :ae_canary,
  mdw_url: mdw_url



# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :ae_canary, AeCanaryWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
