defmodule Mydia.Subtitles.Providers do
  @moduledoc """
  Context module for managing subtitle providers.

  Provides functions for CRUD operations on subtitle providers, similar to
  download client management. Users can configure multiple subtitle sources
  with priorities for automatic selection and fallback.

  ## Usage

      # List all providers for a user
      providers = Providers.list_providers(user_id)

      # Get enabled providers sorted by priority
      enabled = Providers.list_enabled_providers(user_id)

      # Create a new provider
      {:ok, provider} = Providers.create_provider(user_id, %{
        name: "My OpenSubtitles",
        type: :opensubtitles,
        username: "user@example.com",
        password: "password123"
      })

      # Update quota after subtitle download
      {:ok, provider} = Providers.update_quota(provider, 199, ~U[2024-01-01 00:00:00Z])

      # Toggle provider on/off
      {:ok, provider} = Providers.toggle_enabled(provider)

  """

  import Ecto.Query
  require Logger

  alias Mydia.Repo
  alias Mydia.Subtitles.SubtitleProvider

  @doc """
  Lists all subtitle providers for a user.

  Returns providers sorted by priority (highest first), then by name.

  ## Examples

      iex> list_providers(user_id)
      [%SubtitleProvider{name: "Primary", priority: 10}, %SubtitleProvider{name: "Backup", priority: 5}]

  """
  @spec list_providers(binary()) :: [SubtitleProvider.t()]
  def list_providers(user_id) do
    SubtitleProvider
    |> where([p], p.user_id == ^user_id)
    |> order_by([p], desc: p.priority, asc: p.name)
    |> Repo.all()
  end

  @doc """
  Lists only enabled subtitle providers for a user.

  Returns providers sorted by priority (highest first), then by name.
  Used for provider selection during subtitle search.

  ## Examples

      iex> list_enabled_providers(user_id)
      [%SubtitleProvider{enabled: true, priority: 10}, %SubtitleProvider{enabled: true, priority: 5}]

  """
  @spec list_enabled_providers(binary()) :: [SubtitleProvider.t()]
  def list_enabled_providers(user_id) do
    SubtitleProvider
    |> where([p], p.user_id == ^user_id and p.enabled == true)
    |> order_by([p], desc: p.priority, asc: p.name)
    |> Repo.all()
  end

  @doc """
  Gets a single subtitle provider by ID.

  Returns the provider if found, or `nil` if not found.

  ## Examples

      iex> get_provider(provider_id)
      %SubtitleProvider{id: ^provider_id}

      iex> get_provider("nonexistent")
      nil

  """
  @spec get_provider(binary()) :: SubtitleProvider.t() | nil
  def get_provider(id) do
    Repo.get(SubtitleProvider, id)
  end

  @doc """
  Gets a single subtitle provider by ID, raising if not found.

  ## Examples

      iex> get_provider!(provider_id)
      %SubtitleProvider{id: ^provider_id}

      iex> get_provider!("nonexistent")
      ** (Ecto.NoResultsError)

  """
  @spec get_provider!(binary()) :: SubtitleProvider.t()
  def get_provider!(id) do
    Repo.get!(SubtitleProvider, id)
  end

  @doc """
  Gets a provider by user ID and name.

  Useful for finding specific named providers.

  ## Examples

      iex> get_by_name(user_id, "My Provider")
      %SubtitleProvider{name: "My Provider"}

      iex> get_by_name(user_id, "Nonexistent")
      nil

  """
  @spec get_by_name(binary(), String.t()) :: SubtitleProvider.t() | nil
  def get_by_name(user_id, name) do
    SubtitleProvider
    |> where([p], p.user_id == ^user_id and p.name == ^name)
    |> Repo.one()
  end

  @doc """
  Creates a new subtitle provider.

  ## Parameters

    * `user_id` - The user's UUID
    * `attrs` - Map of provider attributes

  ## Examples

      iex> create_provider(user_id, %{name: "Relay", type: :relay})
      {:ok, %SubtitleProvider{}}

      iex> create_provider(user_id, %{name: "Invalid"})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_provider(binary(), map()) ::
          {:ok, SubtitleProvider.t()} | {:error, Ecto.Changeset.t()}
  def create_provider(user_id, attrs) do
    attrs = Map.put(attrs, :user_id, user_id)

    %SubtitleProvider{}
    |> SubtitleProvider.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, provider} ->
        Logger.info("Created subtitle provider",
          provider_id: provider.id,
          name: provider.name,
          type: provider.type,
          user_id: user_id
        )

        {:ok, provider}

      {:error, changeset} ->
        Logger.warning("Failed to create subtitle provider",
          user_id: user_id,
          errors: inspect(changeset.errors)
        )

        {:error, changeset}
    end
  end

  @doc """
  Updates a subtitle provider.

  ## Examples

      iex> update_provider(provider, %{name: "New Name"})
      {:ok, %SubtitleProvider{}}

      iex> update_provider(provider, %{type: :invalid})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_provider(SubtitleProvider.t(), map()) ::
          {:ok, SubtitleProvider.t()} | {:error, Ecto.Changeset.t()}
  def update_provider(provider, attrs) do
    provider
    |> SubtitleProvider.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_provider} ->
        Logger.info("Updated subtitle provider",
          provider_id: provider.id,
          name: updated_provider.name
        )

        {:ok, updated_provider}

      {:error, changeset} ->
        Logger.warning("Failed to update subtitle provider",
          provider_id: provider.id,
          errors: inspect(changeset.errors)
        )

        {:error, changeset}
    end
  end

  @doc """
  Deletes a subtitle provider.

  ## Examples

      iex> delete_provider(provider)
      {:ok, %SubtitleProvider{}}

      iex> delete_provider(provider)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_provider(SubtitleProvider.t()) ::
          {:ok, SubtitleProvider.t()} | {:error, Ecto.Changeset.t()}
  def delete_provider(provider) do
    Repo.delete(provider)
    |> case do
      {:ok, deleted_provider} ->
        Logger.info("Deleted subtitle provider",
          provider_id: provider.id,
          name: provider.name
        )

        {:ok, deleted_provider}

      {:error, changeset} ->
        Logger.error("Failed to delete subtitle provider",
          provider_id: provider.id,
          errors: inspect(changeset.errors)
        )

        {:error, changeset}
    end
  end

  @doc """
  Toggles a provider's enabled status.

  ## Examples

      iex> toggle_enabled(%SubtitleProvider{enabled: true})
      {:ok, %SubtitleProvider{enabled: false}}

      iex> toggle_enabled(%SubtitleProvider{enabled: false})
      {:ok, %SubtitleProvider{enabled: true}}

  """
  @spec toggle_enabled(SubtitleProvider.t()) ::
          {:ok, SubtitleProvider.t()} | {:error, Ecto.Changeset.t()}
  def toggle_enabled(provider) do
    update_provider(provider, %{enabled: !provider.enabled})
  end

  @doc """
  Updates quota information for a provider.

  Used after subtitle downloads to track OpenSubtitles quota usage.
  Relay providers can ignore quota updates.

  ## Parameters

    * `provider` - The SubtitleProvider struct
    * `remaining` - Remaining downloads in quota
    * `reset_at` - DateTime when quota resets
    * `opts` - Optional keyword list:
      * `:total` - Total quota limit (default: keep existing)
      * `:vip` - VIP status (default: keep existing)

  ## Examples

      iex> update_quota(provider, 199, ~U[2024-01-01 00:00:00Z])
      {:ok, %SubtitleProvider{quota_remaining: 199}}

      iex> update_quota(provider, 999, ~U[2024-01-01 00:00:00Z], total: 1000, vip: true)
      {:ok, %SubtitleProvider{quota_remaining: 999, quota_total: 1000, vip_status: true}}

  """
  @spec update_quota(SubtitleProvider.t(), integer(), DateTime.t(), keyword()) ::
          {:ok, SubtitleProvider.t()} | {:error, Ecto.Changeset.t()}
  def update_quota(provider, remaining, reset_at, opts \\ []) do
    attrs = %{
      quota_remaining: remaining,
      quota_reset_at: reset_at
    }

    attrs =
      if total = Keyword.get(opts, :total) do
        Map.put(attrs, :quota_total, total)
      else
        attrs
      end

    attrs =
      if vip = Keyword.get(opts, :vip) do
        Map.put(attrs, :vip_status, vip)
      else
        attrs
      end

    provider
    |> SubtitleProvider.quota_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_provider} ->
        Logger.debug("Updated provider quota",
          provider_id: provider.id,
          remaining: remaining,
          total: updated_provider.quota_total,
          reset_at: reset_at
        )

        {:ok, updated_provider}

      {:error, changeset} ->
        Logger.warning("Failed to update provider quota",
          provider_id: provider.id,
          errors: inspect(changeset.errors)
        )

        {:error, changeset}
    end
  end

  @doc """
  Counts total providers for a user.

  ## Examples

      iex> count_providers(user_id)
      5

  """
  @spec count_providers(binary()) :: integer()
  def count_providers(user_id) do
    SubtitleProvider
    |> where([p], p.user_id == ^user_id)
    |> Repo.aggregate(:count)
  end

  @doc """
  Checks if a user has any enabled providers.

  ## Examples

      iex> has_enabled_providers?(user_id)
      true

  """
  @spec has_enabled_providers?(binary()) :: boolean()
  def has_enabled_providers?(user_id) do
    SubtitleProvider
    |> where([p], p.user_id == ^user_id and p.enabled == true)
    |> Repo.exists?()
  end
end
