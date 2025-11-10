defmodule Mydia.ConfigHelpers do
  @moduledoc """
  Helpers for setting up test configuration, particularly for download clients and indexers.
  """

  alias Mydia.Settings

  @doc """
  Creates a test download client configuration and inserts it into Settings.
  Returns the client configuration map.
  """
  def create_test_download_client(attrs \\ %{}) do
    config = %{
      type: "transmission",
      name: "Test Client #{System.unique_integer([:positive])}",
      host: "localhost",
      port: 9091,
      username: "test",
      password: "test",
      enabled: true
    }

    final_attrs = Map.merge(config, attrs)

    # Create download client config in the database
    {:ok, client_config} = Settings.create_download_client_config(final_attrs)

    client_config
  end

  @doc """
  Creates multiple test download clients.
  Returns a list of client configuration maps.
  """
  def create_test_download_clients(count) when count > 0 do
    Enum.map(1..count, fn i ->
      create_test_download_client(%{
        "name" => "Test Client #{i}",
        "port" => 9090 + i
      })
    end)
  end

  @doc """
  Creates a test indexer configuration.
  Returns the indexer configuration map.
  """
  def create_test_indexer(attrs \\ %{}) do
    id = Ecto.UUID.generate()

    config = %{
      "id" => id,
      "type" => "prowlarr",
      "name" => "Test Indexer #{id}",
      "base_url" => "http://localhost:9696",
      "api_key" => "test_api_key_#{id}",
      "enabled" => true
    }

    Map.merge(config, attrs)
  end

  @doc """
  Clears all test configurations from Settings.
  Should be called in test setup to ensure clean state.
  """
  def clear_test_config do
    # Clear download clients
    Settings.list_download_client_configs()
    |> Enum.each(&Settings.delete_download_client_config/1)

    # Clear indexers
    Settings.list_indexer_configs()
    |> Enum.each(&Settings.delete_indexer_config/1)

    :ok
  rescue
    _ -> :ok
  end
end
