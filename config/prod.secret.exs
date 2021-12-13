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

database_url = "ecto://#{db_user}:#{db_pass}@#{db_host}/#{db_db}"

guardian_secret_key =
  System.get_env("GUARDIAN_SECRET_KEY") ||
    raise """
    environment variable GUARDIAN_SECRET_KEY is missing.
    Please run mix guardian.gen.secret
    """

site_address =
  System.get_env("EMAIL_SITE_ADDRESS") ||
    raise """
    environment variable EMAIL_SITE_ADDRESS is missing.
    This is the address of the AeCanary host to be used where this should be
    shown to the user for example in links in emails
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

defmodule AeCanary.Config.Helpers do
  def get_env_integer(key, default) do
    case Integer.parse(System.get_env(key, default)) do
      {v, _} -> v
      :error -> raise "environment value #{key} must be an integer"
    end
  end

  def get_env_float(key, default) do
    case Float.parse(System.get_env(key, default)) do
      {v, _} -> v
      :error -> raise "environment value #{key} must be a float"
    end
  end

  def get_env_bool(key, default)
      when default == "true" or
             default == "false" do
    case System.get_env(key, default) do
      "true" -> true
      "false" -> false
      _ -> raise "environment value #{key} must be a boolean"
    end
  end
end

config :ae_canary, AeCanaryWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base

config :ae_canary, AeCanary.Accounts.Guardian, secret_key: guardian_secret_key

config :ae_canary,
  site_address: site_address

config :ae_canary, AeCanary.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: System.get_env("EMAIL_API_KEY", ""),
  domain: System.get_env("EMAIL_API_DOMAIN", ""),
  base_uri: System.get_env("EMAIL_MAILGUN_BASE", "https://api.eu.mailgun.net/v3")

alias AeCanary.Config.Helpers, as: H

iqr_lower_boundary_multiplier = H.get_env_float("EXCHANGES_IQR_LOWER_BOUNDARY_MULTILPLIER", "1.5")
iqr_upper_boundary_multiplier = H.get_env_float("EXCHANGES_IQR_UPPER_BOUNDARY_MULTILPLIER", "3")

case iqr_upper_boundary_multiplier < iqr_lower_boundary_multiplier do
  true ->
    raise "EXCHANGES_IQR_UPPER_BOUNDARY_MULTILPLIER must be greater than EXCHANGES_IQR_LOWER_BOUNDARY_MULTILPLIER"

  false ->
    :pass
end

config :ae_canary, AeCanary.Mdw.Cache.Service.Exchange,
  stats_interval_in_days: H.get_env_integer("EXCHANGES_STATS_INTERVAL", "30"),
  show_alerts_interval_in_days: H.get_env_integer("EXCHANGES_ALERTS_INTERVAL", "7"),
  has_transactions_in_the_past_days_interval:
    H.get_env_integer("EXCHANGES_HAS_TXS_INTERVAL", "7"),
  suspicious_deposits_threshold:
    H.get_env_integer("EXCHANGES_SUSPICIOUS_DEPOSIT_THRESHOLD", "500_000"),
  iqr_use_positive_exposure_only:
    H.get_env_bool("EXCHANGES_IQR_USE_POSITIVE_EXPOSURE_ONLY", "true"),
  iqr_lower_boundary_multiplier: iqr_lower_boundary_multiplier,
  iqr_upper_boundary_multiplier: iqr_upper_boundary_multiplier

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :ae_canary, AeCanaryWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
