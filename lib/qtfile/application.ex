defmodule Qtfile.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec
    
    if Application.get_env(:qtfile, :environment) == :dev do
      PhoenixCowboyLogging.enable_for(:qtfile, QtfileWeb.Endpoint)
    end

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Qtfile.Repo, []),
      # Start the endpoint when the application starts
      supervisor(QtfileWeb.Endpoint, []),
      # Start your own worker by calling: Qtfile.Worker.start_link(arg1, arg2, arg3)
      # worker(Qtfile.Worker, [arg1, arg2, arg3]),
      supervisor(QtfileWeb.Presence, []),
      supervisor(Qtfile.Admin.Supervisor, []),
      supervisor(Qtfile.FileProcessing.Supervisor, []),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Qtfile.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    QtfileWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
