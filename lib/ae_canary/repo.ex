defmodule AeCanary.Repo do
  use Ecto.Repo,
    otp_app: :ae_canary,
    adapter: Ecto.Adapters.Postgres
end
