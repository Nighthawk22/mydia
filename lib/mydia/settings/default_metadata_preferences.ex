defmodule Mydia.Settings.DefaultMetadataPreferences do
  @moduledoc """
  Provides default metadata preferences for quality profiles.

  This module defines sensible defaults for metadata preferences that can be
  used when creating new profiles or when no preferences are specified.

  ## Default Configuration

  The default metadata preferences prioritize the metadata-relay service
  (which proxies TVDB and TMDB), with fallback to other providers. It uses
  English (US) as the primary language with fallback to generic English.
  """

  @doc """
  Returns the default metadata preferences map.

  These defaults provide a balanced configuration suitable for most users:
  - Prioritizes metadata-relay for reliability and rate limiting
  - Falls back to TVDB and TMDB if relay is unavailable
  - Uses English (US) with fallback to generic English
  - Enables auto-fetch with weekly refresh
  - Configures sensible fallback and conflict resolution behavior

  ## Examples

      iex> DefaultMetadataPreferences.default()
      %{
        provider_priority: ["metadata_relay", "tvdb", "tmdb"],
        language: "en-US",
        auto_fetch_enabled: true,
        ...
      }
  """
  @spec default() :: map()
  def default do
    %{
      # Provider priority list - try metadata-relay first, then fallback to direct providers
      provider_priority: ["metadata_relay", "tvdb", "tmdb"],

      # No per-field overrides by default (use priority list for all fields)
      field_providers: %{},

      # Language and region preferences - US English by default
      language: "en-US",
      region: "US",
      fallback_languages: ["en"],

      # Auto-fetch settings - enabled with weekly refresh (168 hours = 7 days)
      auto_fetch_enabled: true,
      auto_refresh_interval_hours: 168,

      # Fallback behavior - be resilient to provider failures
      fallback_on_provider_failure: true,
      skip_unavailable_providers: true,

      # Conflict resolution - prefer newer data by default
      conflict_resolution: "prefer_newer",
      merge_strategy: "union"
    }
  end

  @doc """
  Returns metadata preferences optimized for anime content.

  This configuration prioritizes Japanese language metadata and uses providers
  that typically have better anime coverage.

  ## Examples

      iex> DefaultMetadataPreferences.anime_optimized()
      %{
        provider_priority: ["metadata_relay", "tmdb"],
        language: "ja-JP",
        fallback_languages: ["ja", "en"],
        ...
      }
  """
  @spec anime_optimized() :: map()
  def anime_optimized do
    %{
      provider_priority: ["metadata_relay", "tmdb"],
      field_providers: %{},
      language: "ja-JP",
      region: "JP",
      fallback_languages: ["ja", "en"],
      auto_fetch_enabled: true,
      auto_refresh_interval_hours: 168,
      fallback_on_provider_failure: true,
      skip_unavailable_providers: true,
      conflict_resolution: "prefer_newer",
      merge_strategy: "union"
    }
  end

  @doc """
  Returns metadata preferences optimized for TV shows.

  This configuration prioritizes TVDB which typically has more comprehensive
  TV show metadata including episode-level details.

  ## Examples

      iex> DefaultMetadataPreferences.tv_optimized()
      %{
        provider_priority: ["metadata_relay", "tvdb", "tmdb"],
        field_providers: %{
          "episode_name" => "tvdb",
          "season_info" => "tvdb"
        },
        ...
      }
  """
  @spec tv_optimized() :: map()
  def tv_optimized do
    default()
    |> Map.put(:field_providers, %{
      "episode_name" => "tvdb",
      "season_info" => "tvdb",
      "air_date" => "tvdb"
    })
  end

  @doc """
  Returns metadata preferences optimized for movies.

  This configuration prioritizes TMDB which typically has better movie
  metadata including crew, cast, and production details.

  ## Examples

      iex> DefaultMetadataPreferences.movie_optimized()
      %{
        provider_priority: ["metadata_relay", "tmdb", "tvdb"],
        field_providers: %{
          "cast" => "tmdb",
          "crew" => "tmdb",
          "poster" => "tmdb"
        },
        ...
      }
  """
  @spec movie_optimized() :: map()
  def movie_optimized do
    default()
    |> Map.put(:provider_priority, ["metadata_relay", "tmdb"])
    |> Map.put(:field_providers, %{
      "cast" => "tmdb",
      "crew" => "tmdb",
      "poster" => "tmdb",
      "backdrop" => "tmdb"
    })
  end

  @doc """
  Returns minimal metadata preferences with auto-fetch disabled.

  This configuration is useful for users who want to manually control
  metadata fetching or have limited API quota.

  ## Examples

      iex> DefaultMetadataPreferences.minimal()
      %{
        provider_priority: ["metadata_relay"],
        auto_fetch_enabled: false,
        ...
      }
  """
  @spec minimal() :: map()
  def minimal do
    %{
      provider_priority: ["metadata_relay"],
      field_providers: %{},
      language: "en-US",
      region: "US",
      fallback_languages: [],
      auto_fetch_enabled: false,
      auto_refresh_interval_hours: 0,
      fallback_on_provider_failure: false,
      skip_unavailable_providers: true,
      conflict_resolution: "manual",
      merge_strategy: "priority"
    }
  end

  @doc """
  Merges custom preferences with defaults.

  Accepts a partial preferences map and fills in missing fields with defaults.
  This is useful when you want to override specific fields while keeping
  the rest at default values.

  ## Examples

      iex> DefaultMetadataPreferences.with_defaults(%{language: "fr-FR"})
      %{
        provider_priority: ["metadata_relay", "tvdb", "tmdb"],
        language: "fr-FR",
        region: "US",
        ...
      }

      iex> DefaultMetadataPreferences.with_defaults(%{
        language: "ja-JP",
        auto_fetch_enabled: false
      })
      %{
        provider_priority: ["metadata_relay", "tvdb", "tmdb"],
        language: "ja-JP",
        auto_fetch_enabled: false,
        ...
      }
  """
  @spec with_defaults(map()) :: map()
  def with_defaults(custom_prefs) when is_map(custom_prefs) do
    Map.merge(default(), custom_prefs)
  end

  @doc """
  Validates that required providers are available in the system.

  Checks that all providers referenced in the preferences (both in
  provider_priority and field_providers) are registered in the
  Metadata.Provider.Registry.

  Returns `{:ok, preferences}` if all providers are available, or
  `{:error, missing_providers}` if some providers are not registered.

  ## Examples

      iex> prefs = %{provider_priority: ["metadata_relay", "tvdb"]}
      iex> DefaultMetadataPreferences.validate_providers(prefs)
      {:ok, prefs}

      iex> prefs = %{provider_priority: ["invalid_provider"]}
      iex> DefaultMetadataPreferences.validate_providers(prefs)
      {:error, ["invalid_provider"]}
  """
  @spec validate_providers(map()) :: {:ok, map()} | {:error, [String.t()]}
  def validate_providers(prefs) when is_map(prefs) do
    # Get all provider names from both priority list and field providers
    priority_providers = Map.get(prefs, :provider_priority, [])
    field_providers = Map.get(prefs, :field_providers, %{}) |> Map.values()
    all_providers = Enum.uniq(priority_providers ++ field_providers)

    # Check which providers are not registered
    missing =
      Enum.reject(all_providers, fn provider ->
        provider_atom = to_provider_atom(provider)
        Mydia.Metadata.Provider.Registry.registered?(provider_atom)
      end)

    if Enum.empty?(missing) do
      {:ok, prefs}
    else
      {:error, missing}
    end
  end

  # Converts a provider name (string or atom) to an atom
  defp to_provider_atom(provider) when is_atom(provider), do: provider
  defp to_provider_atom(provider) when is_binary(provider), do: String.to_atom(provider)
end
