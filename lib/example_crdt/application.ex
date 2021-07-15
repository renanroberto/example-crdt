defmodule ExampleCRDT.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      ExampleCRDT.Repo,
      # Start the Telemetry supervisor
      ExampleCRDTWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: ExampleCRDT.PubSub},
      # Start the Endpoint (http/https)
      ExampleCRDTWeb.Endpoint,
      # Start a worker by calling: ExampleCRDT.Worker.start_link(arg)
      # {ExampleCRDT.Worker, arg}
      ExampleCRDT.Supervisor.Counter
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExampleCRDT.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ExampleCRDTWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
