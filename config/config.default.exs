# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :qtfile,
  ecto_repos: [Qtfile.Repo],
  token_secret_key_base: "REPLACE THIS",
  secret_key_ip: "REPLACE THIS",
  environment: Mix.env()

# Configures the endpoint
config :qtfile, QtfileWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "REPLACE THIS",
  render_errors: [view: QtfileWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Qtfile.PubSub,
           adapter: Phoenix.PubSub.PG2],
  max_file_length: 4 * 1024 * 1024 * 1024

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :arc,
  storage: Arc.Storage.Local,
  storage_dir: "uploads/rooms"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
