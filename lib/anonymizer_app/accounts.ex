defmodule AnonymizerApp.Accounts do
  import Ecto.Query, warn: false
  alias AnonymizerApp.Repo
  alias AnonymizerApp.Accounts.ApiKey

  # List all API keys
  def list_api_keys do
    Repo.all(ApiKey)
  end

  # Get a single API key by ID (raises if not found)
  def get_api_key!(id) do
    Repo.get!(ApiKey, id)
  end

  # Create an API key with attributes map
  def create_api_key(attrs \\ %{}) do
    %ApiKey{}
    |> ApiKey.changeset(attrs)
    |> Repo.insert()
  end

  # Update an existing API key struct with new attrs
  def update_api_key(%ApiKey{} = api_key, attrs) do
    api_key
    |> ApiKey.changeset(attrs)
    |> Repo.update()
  end

  # Delete an API key struct
  def delete_api_key(%ApiKey{} = api_key) do
    Repo.delete(api_key)
  end

  # Returns a changeset for an API key - useful for forms
  def change_api_key(%ApiKey{} = api_key, attrs \\ %{}) do
    ApiKey.changeset(api_key, attrs)
  end
end
