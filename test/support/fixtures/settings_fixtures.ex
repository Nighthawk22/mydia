defmodule Mydia.SettingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Mydia.Settings` context.
  """

  alias Mydia.Settings

  @doc """
  Generate a download client config.
  """
  def download_client_config_fixture(attrs \\ %{}) do
    default_attrs = %{
      name: "test-client-#{System.unique_integer([:positive])}",
      type: "qbittorrent",
      enabled: true,
      priority: 1,
      host: "localhost",
      port: 8080,
      use_ssl: false,
      username: "admin",
      password: "adminpass"
    }

    attrs = Map.merge(default_attrs, attrs)

    {:ok, client_config} = Settings.create_download_client_config(attrs)
    client_config
  end

  @doc """
  Generate a quality profile.
  """
  def quality_profile_fixture(attrs \\ %{}) do
    default_attrs = %{
      name: "test-profile-#{System.unique_integer([:positive])}",
      min_size: 0,
      max_size: 10_737_418_240,
      preferred_qualities: ["1080p", "720p"]
    }

    attrs = Map.merge(default_attrs, attrs)

    {:ok, profile} = Settings.create_quality_profile(attrs)
    profile
  end

  @doc """
  Generate an indexer config.
  """
  def indexer_config_fixture(attrs \\ %{}) do
    default_attrs = %{
      name: "test-indexer-#{System.unique_integer([:positive])}",
      type: :prowlarr,
      enabled: true,
      priority: 1,
      base_url: "http://localhost:9696",
      api_key: "test-api-key"
    }

    attrs = Map.merge(default_attrs, attrs)

    {:ok, indexer} = Settings.create_indexer_config(attrs)
    indexer
  end
end
