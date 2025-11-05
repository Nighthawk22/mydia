defmodule Mydia.Metadata.Cache do
  @moduledoc """
  Simple ETS-based cache for metadata API responses.

  This cache helps reduce redundant API calls to the metadata relay service
  by caching responses for a configurable TTL.
  """

  use GenServer
  require Logger

  @table_name :metadata_cache
  @default_ttl :timer.hours(1)

  @doc """
  Starts the cache GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets a value from the cache by key.

  Returns `{:ok, value}` if the key exists and hasn't expired,
  or `{:error, :not_found}` otherwise.
  """
  def get(key) do
    case :ets.lookup(@table_name, key) do
      [{^key, value, expires_at}] ->
        if System.system_time(:millisecond) < expires_at do
          {:ok, value}
        else
          # Entry expired, delete it
          :ets.delete(@table_name, key)
          {:error, :not_found}
        end

      [] ->
        {:error, :not_found}
    end
  end

  @doc """
  Puts a value in the cache with the given key and TTL.

  ## Options

    * `:ttl` - Time to live in milliseconds (default: 1 hour)
  """
  def put(key, value, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @default_ttl)
    expires_at = System.system_time(:millisecond) + ttl
    :ets.insert(@table_name, {key, value, expires_at})
    :ok
  end

  @doc """
  Fetches a value from the cache, or computes it using the given function.

  If the key exists in the cache and hasn't expired, returns the cached value.
  Otherwise, calls the function, stores the result in the cache, and returns it.

  ## Options

    * `:ttl` - Time to live in milliseconds (default: 1 hour)

  ## Examples

      iex> Mydia.Metadata.Cache.fetch("trending_movies", fn ->
      ...>   Mydia.Metadata.trending_movies()
      ...> end)
      {:ok, [%{title: "Movie 1", ...}]}
  """
  def fetch(key, fun, opts \\ []) when is_function(fun, 0) do
    case get(key) do
      {:ok, value} ->
        {:ok, value}

      {:error, :not_found} ->
        case fun.() do
          {:ok, value} = result ->
            put(key, value, opts)
            result

          error ->
            error
        end
    end
  end

  @doc """
  Deletes a value from the cache by key.
  """
  def delete(key) do
    :ets.delete(@table_name, key)
    :ok
  end

  @doc """
  Clears all entries from the cache.
  """
  def clear do
    :ets.delete_all_objects(@table_name)
    :ok
  end

  ## GenServer Callbacks

  @impl true
  def init(_opts) do
    :ets.new(@table_name, [:named_table, :set, :public, read_concurrency: true])
    Logger.info("Metadata cache started")

    # Schedule periodic cleanup of expired entries
    schedule_cleanup()

    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_expired_entries()
    schedule_cleanup()
    {:noreply, state}
  end

  ## Private Functions

  defp schedule_cleanup do
    # Run cleanup every 10 minutes
    Process.send_after(self(), :cleanup, :timer.minutes(10))
  end

  defp cleanup_expired_entries do
    now = System.system_time(:millisecond)

    expired_count =
      :ets.select_delete(@table_name, [
        {{:"$1", :"$2", :"$3"}, [{:<, :"$3", now}], [true]}
      ])

    if expired_count > 0 do
      Logger.debug("Cleaned up #{expired_count} expired cache entries")
    end
  end
end
