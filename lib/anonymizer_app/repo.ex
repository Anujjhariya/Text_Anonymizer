defmodule AnonymizerApp.Repo do
  use Ecto.Repo,
    otp_app: :anonymizer_app,
    adapter: Ecto.Adapters.Postgres
end
