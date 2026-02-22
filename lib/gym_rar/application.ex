defmodule GymRar.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GymRarWeb.Telemetry,
      GymRar.Repo,
      {DNSCluster, query: Application.get_env(:gym_rar, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GymRar.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: GymRar.Finch},
      # Start a worker by calling: GymRar.Worker.start_link(arg)
      # {GymRar.Worker, arg},
      # Start to serve requests, typically the last entry
      GymRarWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GymRar.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GymRarWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
