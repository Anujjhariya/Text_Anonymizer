defmodule AnonymizerApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AnonymizerApp.Repo,
      AnonymizerAppWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:anonymizer_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AnonymizerApp.PubSub},
      {Finch, name: MyFinch},
      # Start a worker by calling: AnonymizerApp.Worker.start_link(arg)
      # {AnonymizerApp.Worker, arg},
      # Start to serve requests, typically the last entry
      AnonymizerAppWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AnonymizerApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AnonymizerAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
