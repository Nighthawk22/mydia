defmodule Mydia.Config do
  @moduledoc """
  Public API for accessing application configuration.

  Provides a simple interface for retrieving the runtime configuration
  which is loaded from multiple sources with precedence:
  Environment Variables > Database/UI Settings > YAML File > Schema Defaults

  See `Mydia.Config.Loader` and `Mydia.Config.Schema` for implementation details.
  """

  alias Mydia.Settings

  @doc """
  Gets the current runtime configuration.

  Returns the merged configuration from all sources according to precedence rules.
  The configuration is loaded at application startup and cached in the application
  environment.

  ## Examples

      iex> config = Mydia.Config.get()
      iex> config.media.monitor_by_default
      true

      iex> config = Mydia.Config.get()
      iex> config.media.auto_search_on_add
      true

  """
  @spec get() :: Mydia.Config.Schema.t()
  def get do
    Settings.get_runtime_config()
  end
end
