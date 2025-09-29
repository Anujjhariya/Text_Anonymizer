# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :anonymizer_app,
  generators: [timestamp_type: :utc_datetime]


config :anonymizer_app, ecto_repos: [AnonymizerApp.Repo]

config :anonymizer_app, AnonymizerApp.Repo,
  username: "myuser",
  password: "mypassword",
  database: "multi_tenant_router",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10



# Configures the endpoint
config :anonymizer_app, AnonymizerAppWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: AnonymizerAppWeb.ErrorHTML, json: AnonymizerAppWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: AnonymizerApp.PubSub,
  live_view: [signing_salt: "tOOOz2yK"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :anonymizer_app, AnonymizerApp.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  anonymizer_app: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  anonymizer_app: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason


# Tesla deprecated builder warning suppression
config :tesla, disable_deprecated_builder_warning: true


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
