defmodule AnonymizerApp.Accounts.ApiKey do
  use Ecto.Schema
  import Ecto.Changeset

  alias AnonymizerApp.Accounts.User
  alias AnonymizerApp.AI.AIModel

  schema "api_keys" do
    field :key, :string
    field :tokens_remaining, :integer, default: 0
    field :is_active, :boolean, default: true

    belongs_to :owner, User
    belongs_to :model, AIModel

    timestamps(inserted_at: :created_at)
  end

  def changeset(api_key, attrs) do
    api_key
    |> cast(attrs, [:key, :tokens_remaining, :is_active, :owner_id, :model_id])
    |> validate_required([:key, :tokens_remaining, :is_active, :owner_id, :model_id])
    |> unique_constraint(:key)
  end
end
