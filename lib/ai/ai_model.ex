defmodule AnonymizerApp.AI.AIModel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ai_models" do
    field :name, :string
    field :description, :string
    field :file_path, :string
    field :owner_id, :integer   # optional if you want to track owner/user of model

    timestamps()
  end

  def changeset(ai_model, attrs) do
    ai_model
    |> cast(attrs, [:name, :description, :file_path, :owner_id])
    |> validate_required([:name, :file_path])
  end
end
