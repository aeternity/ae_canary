defmodule AeCanary.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      AeCanary.Repo,
      # Start the Telemetry supervisor
      AeCanaryWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: AeCanary.PubSub},
      # Start the Endpoint (http/https)
      AeCanaryWeb.Endpoint,
      # Start a worker by calling: AeCanary.Worker.start_link(arg)
      # {AeCanary.Worker, arg}
      :poolboy.child_spec(:worker, AeCanary.Mdw.poolboy_spec()),
      AeCanary.Mdw.Cache
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AeCanary.Supervisor]
    HTTPoison.start
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    AeCanaryWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
