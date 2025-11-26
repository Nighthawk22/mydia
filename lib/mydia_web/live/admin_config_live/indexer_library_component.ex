defmodule MydiaWeb.AdminConfigLive.IndexerLibraryComponent do
  @moduledoc """
  LiveComponent for managing the indexer library.

  This component provides a modal interface for browsing, searching, and enabling
  indexers from the built-in indexer definition library.
  """
  use MydiaWeb, :live_component

  alias Mydia.Indexers
  alias Mydia.Indexers.CardigannDefinition

  require Logger
  alias Mydia.Logger, as: MydiaLogger

  @impl true
  def update(%{sync_result: result} = _assigns, socket) do
    # Handle sync completion result from parent LiveView
    socket =
      case result do
        {:ok, stats} ->
          socket
          |> assign(:syncing, false)
          |> put_flash(
            :info,
            "Sync completed: #{stats.created} created, #{stats.updated} updated, #{stats.failed} failed"
          )
          |> load_indexers()

        {:error, reason} ->
          Logger.error("[IndexerLibrary] Sync failed: #{inspect(reason)}")

          socket
          |> assign(:syncing, false)
          |> put_flash(:error, "Sync failed: #{format_sync_error(reason)}")
      end

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:filter_type, fn -> "all" end)
      |> assign_new(:filter_language, fn -> "all" end)
      |> assign_new(:filter_enabled, fn -> "all" end)
      |> assign_new(:search_query, fn -> "" end)
      |> assign_new(:show_config_modal, fn -> false end)
      |> assign_new(:configuring_definition, fn -> nil end)
      |> assign_new(:syncing, fn -> false end)
      |> load_indexers()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="modal modal-open">
      <div class="modal-box max-w-5xl max-h-[90vh]">
        <%!-- Header with Close Button --%>
        <div class="flex items-center justify-between mb-4">
          <div>
            <h3 class="font-bold text-lg flex items-center gap-2">
              <.icon name="hero-book-open" class="w-5 h-5 opacity-60" /> Indexer Library
            </h3>
            <p class="text-base-content/70 text-sm mt-1">
              Browse and enable indexers from the definition library
            </p>
          </div>
          <button
            class="btn btn-sm btn-ghost btn-circle"
            phx-click="close_indexer_library"
            title="Close"
          >
            <.icon name="hero-x-mark" class="w-5 h-5" />
          </button>
        </div>
        <%!-- Filters and Search --%>
        <div class="card bg-base-200 shadow-sm mb-4">
          <div class="card-body p-4">
            <div class="flex flex-wrap gap-4 items-end">
              <%!-- Search --%>
              <div class="form-control flex-1 min-w-48">
                <label class="label py-1">
                  <span class="label-text text-xs">Search</span>
                </label>
                <form id="indexer-library-search-form" phx-change="search" phx-target={@myself}>
                  <input
                    type="text"
                    name="search[query]"
                    value={@search_query}
                    placeholder="Search by name or description..."
                    class="input input-bordered input-sm w-full"
                  />
                </form>
              </div>
              <%!-- Filter Dropdowns --%>
              <.form
                for={%{}}
                id="indexer-library-filter-form"
                phx-change="filter"
                phx-target={@myself}
                class="contents"
              >
                <%!-- Type Filter --%>
                <div class="form-control">
                  <label class="label py-1">
                    <span class="label-text text-xs">Type</span>
                  </label>
                  <select class="select select-bordered select-sm" name="type">
                    <option value="all" selected={@filter_type == "all"}>All Types</option>
                    <option value="public" selected={@filter_type == "public"}>Public</option>
                    <option value="private" selected={@filter_type == "private"}>Private</option>
                    <option value="semi-private" selected={@filter_type == "semi-private"}>
                      Semi-Private
                    </option>
                  </select>
                </div>
                <%!-- Language Filter --%>
                <div class="form-control">
                  <label class="label py-1">
                    <span class="label-text text-xs">Language</span>
                  </label>
                  <select class="select select-bordered select-sm" name="language">
                    <option value="all" selected={@filter_language == "all"}>All Languages</option>
                    <%= for language <- @available_languages do %>
                      <option value={language} selected={@filter_language == language}>
                        {language}
                      </option>
                    <% end %>
                  </select>
                </div>
                <%!-- Status Filter --%>
                <div class="form-control">
                  <label class="label py-1">
                    <span class="label-text text-xs">Status</span>
                  </label>
                  <select class="select select-bordered select-sm" name="enabled">
                    <option value="all" selected={@filter_enabled == "all"}>All Status</option>
                    <option value="enabled" selected={@filter_enabled == "enabled"}>Enabled</option>
                    <option value="disabled" selected={@filter_enabled == "disabled"}>
                      Disabled
                    </option>
                  </select>
                </div>
              </.form>
              <%!-- Sync Button --%>
              <div class="form-control">
                <button
                  class={["btn btn-primary btn-sm", @syncing && "btn-disabled"]}
                  phx-click="sync_definitions"
                  phx-target={@myself}
                  disabled={@syncing}
                >
                  <%= if @syncing do %>
                    <span class="loading loading-spinner loading-xs"></span> Syncing...
                  <% else %>
                    <.icon name="hero-arrow-path" class="w-4 h-4" /> Sync Library
                  <% end %>
                </button>
              </div>
            </div>
          </div>
        </div>
        <%!-- Indexer List --%>
        <div class="overflow-y-auto max-h-[50vh]">
          <%= if @definitions == [] do %>
            <div class="alert alert-info">
              <.icon name="hero-information-circle" class="w-5 h-5" />
              <span>
                <%= if @search_query != "" or @filter_type != "all" or @filter_language != "all" or @filter_enabled != "all" do %>
                  No indexers match your filters. Try adjusting your search criteria.
                <% else %>
                  No indexer definitions available. Click "Sync Library" to fetch indexers from the repository.
                <% end %>
              </span>
            </div>
          <% else %>
            <div class="bg-base-200 rounded-box divide-y divide-base-300">
              <%= for definition <- @definitions do %>
                <div class="p-3 sm:p-4">
                  <div class="flex flex-col sm:flex-row sm:items-center gap-3">
                    <%!-- Indexer Info --%>
                    <div class="flex-1 min-w-0">
                      <div class="font-semibold flex items-center gap-2 flex-wrap">
                        {definition.name}
                        <span class={"badge badge-sm #{indexer_type_badge_class(definition.type)}"}>
                          {definition.type}
                        </span>
                        <%= if definition.language do %>
                          <span class="badge badge-sm badge-ghost">{definition.language}</span>
                        <% end %>
                      </div>
                      <%= if definition.description do %>
                        <div class="text-sm text-base-content/70 mt-1 line-clamp-1">
                          {definition.description}
                        </div>
                      <% end %>
                    </div>
                    <%!-- Status and Health --%>
                    <div class="flex items-center gap-3 flex-wrap">
                      <span class={"badge badge-sm #{indexer_status_class(definition)}"}>
                        {indexer_status_label(definition)}
                      </span>
                      <%= if needs_configuration?(definition) and definition.enabled do %>
                        <div class="tooltip" data-tip="This indexer requires configuration">
                          <.icon name="hero-exclamation-triangle" class="w-4 h-4 text-warning" />
                        </div>
                      <% end %>
                      <%= if definition.enabled and definition.health_status not in [nil, "unknown"] do %>
                        <span class={"badge badge-sm #{health_status_badge_class(definition.health_status)}"}>
                          {health_status_label(definition.health_status)}
                        </span>
                      <% end %>
                    </div>
                    <%!-- Actions --%>
                    <div class="flex items-center gap-3">
                      <%!-- Enable/Disable toggle with label --%>
                      <label class="flex items-center gap-1.5 cursor-pointer">
                        <span class="text-xs text-base-content/60">Enable</span>
                        <input
                          type="checkbox"
                          class="toggle toggle-success toggle-sm"
                          checked={definition.enabled}
                          phx-click="toggle_indexer"
                          phx-target={@myself}
                          phx-value-id={definition.id}
                        />
                      </label>

                      <%!-- FlareSolverr toggle with label and icon --%>
                      <div
                        class="tooltip tooltip-left"
                        data-tip={
                          if definition.flaresolverr_required,
                            do: "Cloudflare bypass (recommended for this indexer)",
                            else: "Enable Cloudflare bypass via FlareSolverr"
                        }
                      >
                        <label class="flex items-center gap-1.5 cursor-pointer">
                          <.icon
                            name="hero-shield-check"
                            class={"w-4 h-4 #{if(definition.flaresolverr_enabled, do: "text-warning", else: "text-base-content/30")}"}
                          />
                          <span class="text-xs text-base-content/60">CF</span>
                          <input
                            type="checkbox"
                            class={[
                              "toggle toggle-sm",
                              if(definition.flaresolverr_required,
                                do: "toggle-warning",
                                else: "toggle-info"
                              )
                            ]}
                            checked={definition.flaresolverr_enabled}
                            phx-click="toggle_flaresolverr"
                            phx-target={@myself}
                            phx-value-id={definition.id}
                          />
                        </label>
                      </div>

                      <%!-- Action buttons --%>
                      <%= if definition.enabled do %>
                        <button
                          class="btn btn-sm btn-ghost"
                          phx-click="test_connection"
                          phx-target={@myself}
                          phx-value-id={definition.id}
                          title="Test Connection"
                        >
                          <.icon name="hero-signal" class="w-4 h-4" />
                        </button>
                      <% end %>
                      <%= if definition.type in ["private", "semi-private"] do %>
                        <button
                          class="btn btn-sm btn-ghost"
                          phx-click="configure_indexer"
                          phx-target={@myself}
                          phx-value-id={definition.id}
                          title="Configure"
                        >
                          <.icon name="hero-cog-6-tooth" class="w-4 h-4" />
                        </button>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
        <%!-- Modal Footer --%>
        <div class="modal-action">
          <button class="btn" phx-click="close_indexer_library">Close</button>
        </div>
      </div>
      <div class="modal-backdrop" phx-click="close_indexer_library"></div>
      <%!-- Configuration Modal (nested) --%>
      <%= if @show_config_modal do %>
        <div class="modal modal-open z-50">
          <div class="modal-box max-w-2xl">
            <h3 class="font-bold text-lg mb-4">
              Configure {@configuring_definition.name}
            </h3>

            <div class="alert alert-info mb-4">
              <.icon name="hero-information-circle" class="w-5 h-5" />
              <span>
                Private indexers require authentication. Enter your credentials below.
              </span>
            </div>

            <form id="indexer-config-form" phx-submit="save_config" phx-target={@myself}>
              <div class="space-y-4">
                <%!-- Username --%>
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Username</span>
                  </label>
                  <input
                    type="text"
                    name="config[username]"
                    value={get_in(@configuring_definition.config || %{}, ["username"])}
                    class="input input-bordered"
                    placeholder="Your indexer username"
                  />
                </div>
                <%!-- Password --%>
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Password</span>
                  </label>
                  <input
                    type="password"
                    name="config[password]"
                    value={get_in(@configuring_definition.config || %{}, ["password"])}
                    class="input input-bordered"
                    placeholder="Your indexer password"
                  />
                </div>
                <%!-- API Key (optional) --%>
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">API Key (if applicable)</span>
                  </label>
                  <input
                    type="password"
                    name="config[api_key]"
                    value={get_in(@configuring_definition.config || %{}, ["api_key"])}
                    class="input input-bordered"
                    placeholder="Optional API key"
                  />
                </div>
                <%!-- Cookie (optional) --%>
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Cookie String (if applicable)</span>
                  </label>
                  <textarea
                    name="config[cookie]"
                    rows="3"
                    class="textarea textarea-bordered"
                    placeholder="Optional cookie string for authentication"
                  >{get_in(@configuring_definition.config || %{}, ["cookie"])}</textarea>
                </div>
              </div>

              <div class="modal-action">
                <button
                  type="button"
                  class="btn"
                  phx-click="close_config_modal"
                  phx-target={@myself}
                >
                  Cancel
                </button>
                <button type="submit" class="btn btn-primary">Save Configuration</button>
              </div>
            </form>
          </div>
          <div class="modal-backdrop" phx-click="close_config_modal" phx-target={@myself}></div>
        </div>
      <% end %>
    </div>
    """
  end

  ## Event Handlers

  @impl true
  def handle_event("filter", params, socket) do
    {:noreply,
     socket
     |> assign(:filter_type, params["type"] || socket.assigns.filter_type)
     |> assign(:filter_language, params["language"] || socket.assigns.filter_language)
     |> assign(:filter_enabled, params["enabled"] || socket.assigns.filter_enabled)
     |> load_indexers()}
  end

  @impl true
  def handle_event("search", %{"search" => %{"query" => query}}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> load_indexers()}
  end

  @impl true
  def handle_event("toggle_indexer", %{"id" => id}, socket) do
    definition = Indexers.get_cardigann_definition!(id)

    result =
      if definition.enabled do
        Indexers.disable_cardigann_definition(definition)
      else
        Indexers.enable_cardigann_definition(definition)
      end

    case result do
      {:ok, updated_definition} ->
        action = if updated_definition.enabled, do: "enabled", else: "disabled"

        # Notify the parent LiveView to reload its library indexers data
        send(self(), :reload_library_indexers)

        {:noreply,
         socket
         |> put_flash(:info, "Indexer #{action} successfully")
         |> load_indexers()}

      {:error, changeset} ->
        MydiaLogger.log_error(:liveview, "Failed to toggle indexer",
          error: changeset,
          operation: :toggle_library_indexer,
          definition_id: id,
          user_id: socket.assigns.current_user.id
        )

        error_msg = MydiaLogger.user_error_message(:toggle_library_indexer, changeset)

        {:noreply,
         socket
         |> put_flash(:error, error_msg)}
    end
  end

  @impl true
  def handle_event("toggle_flaresolverr", %{"id" => id}, socket) do
    definition = Indexers.get_cardigann_definition!(id)
    new_enabled = !definition.flaresolverr_enabled

    case Indexers.update_flaresolverr_settings(definition, %{flaresolverr_enabled: new_enabled}) do
      {:ok, updated_definition} ->
        action = if updated_definition.flaresolverr_enabled, do: "enabled", else: "disabled"

        {:noreply,
         socket
         |> put_flash(:info, "FlareSolverr #{action} for #{definition.name}")
         |> load_indexers()}

      {:error, changeset} ->
        MydiaLogger.log_error(:liveview, "Failed to toggle FlareSolverr",
          error: changeset,
          operation: :toggle_flaresolverr,
          definition_id: id,
          user_id: socket.assigns.current_user.id
        )

        error_msg = MydiaLogger.user_error_message(:toggle_flaresolverr, changeset)

        {:noreply,
         socket
         |> put_flash(:error, error_msg)}
    end
  end

  @impl true
  def handle_event("configure_indexer", %{"id" => id}, socket) do
    definition = Indexers.get_cardigann_definition!(id)

    {:noreply,
     socket
     |> assign(:show_config_modal, true)
     |> assign(:configuring_definition, definition)}
  end

  @impl true
  def handle_event("close_config_modal", _params, socket) do
    {:noreply, assign(socket, :show_config_modal, false)}
  end

  @impl true
  def handle_event("save_config", %{"config" => config_params}, socket) do
    definition = socket.assigns.configuring_definition

    case Indexers.configure_cardigann_definition(definition, config_params) do
      {:ok, _updated_definition} ->
        {:noreply,
         socket
         |> assign(:show_config_modal, false)
         |> put_flash(:info, "Configuration saved successfully")
         |> load_indexers()}

      {:error, changeset} ->
        MydiaLogger.log_error(:liveview, "Failed to configure indexer",
          error: changeset,
          operation: :configure_library_indexer,
          definition_id: definition.id,
          user_id: socket.assigns.current_user.id
        )

        error_msg = MydiaLogger.user_error_message(:configure_library_indexer, changeset)

        {:noreply,
         socket
         |> put_flash(:error, error_msg)}
    end
  end

  @impl true
  def handle_event("sync_definitions", _params, socket) do
    # Run sync in a separate process to avoid blocking the LiveView
    # Use send_update to notify this component when sync completes
    parent = self()
    component_id = socket.assigns.id

    Task.start(fn ->
      result = Mydia.Indexers.DefinitionSync.sync_from_github()
      send(parent, {:sync_complete, component_id, result})
    end)

    {:noreply,
     socket
     |> assign(:syncing, true)
     |> put_flash(:info, "Sync started - this may take a few minutes...")}
  end

  @impl true
  def handle_event("test_connection", %{"id" => id}, socket) do
    case Indexers.test_cardigann_connection(id) do
      {:ok, result} ->
        flash_message =
          if result.success do
            "Connection successful (#{result.response_time_ms}ms)"
          else
            "Connection failed: #{result.error || "Unknown error"}"
          end

        flash_type = if result.success, do: :info, else: :error

        {:noreply,
         socket
         |> put_flash(flash_type, flash_message)
         |> load_indexers()}

      {:error, reason} ->
        MydiaLogger.log_error(:liveview, "Failed to test connection",
          error: reason,
          operation: :test_library_indexer_connection,
          definition_id: id,
          user_id: socket.assigns.current_user.id
        )

        {:noreply,
         socket
         |> put_flash(:error, "Failed to test connection: #{inspect(reason)}")}
    end
  end

  ## Private Functions

  defp load_indexers(socket) do
    filters = build_filters(socket.assigns)
    definitions = Indexers.list_cardigann_definitions(filters)

    # Get unique languages from all definitions for filter dropdown
    all_definitions = Indexers.list_cardigann_definitions()

    languages =
      all_definitions
      |> Enum.map(& &1.language)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()

    socket
    |> assign(:definitions, definitions)
    |> assign(:available_languages, languages)
  end

  defp build_filters(assigns) do
    filters = []

    filters =
      if assigns.filter_type != "all" do
        [{:type, assigns.filter_type} | filters]
      else
        filters
      end

    filters =
      if assigns.filter_language != "all" do
        [{:language, assigns.filter_language} | filters]
      else
        filters
      end

    filters =
      case assigns.filter_enabled do
        "enabled" -> [{:enabled, true} | filters]
        "disabled" -> [{:enabled, false} | filters]
        _ -> filters
      end

    filters =
      if assigns.search_query != "" do
        [{:search, assigns.search_query} | filters]
      else
        filters
      end

    filters
  end

  defp indexer_type_badge_class("public"), do: "badge-success"
  defp indexer_type_badge_class("private"), do: "badge-error"
  defp indexer_type_badge_class("semi-private"), do: "badge-warning"
  defp indexer_type_badge_class(_), do: "badge-ghost"

  defp indexer_status_class(%CardigannDefinition{enabled: false}), do: "badge-ghost"

  defp indexer_status_class(%CardigannDefinition{enabled: true, type: "private", config: nil}),
    do: "badge-warning"

  defp indexer_status_class(%CardigannDefinition{enabled: true, type: "private", config: config})
       when config == %{},
       do: "badge-warning"

  defp indexer_status_class(%CardigannDefinition{enabled: true}), do: "badge-success"

  defp indexer_status_label(%CardigannDefinition{enabled: false}), do: "Disabled"

  defp indexer_status_label(%CardigannDefinition{enabled: true, type: "private", config: nil}),
    do: "Needs Config"

  defp indexer_status_label(%CardigannDefinition{enabled: true, type: "private", config: config})
       when config == %{},
       do: "Needs Config"

  defp indexer_status_label(%CardigannDefinition{enabled: true}), do: "Enabled"

  defp needs_configuration?(%CardigannDefinition{type: "public"}), do: false

  defp needs_configuration?(%CardigannDefinition{
         type: type,
         config: nil
       })
       when type in ["private", "semi-private"],
       do: true

  defp needs_configuration?(%CardigannDefinition{type: type, config: config})
       when type in ["private", "semi-private"] and config == %{},
       do: true

  defp needs_configuration?(_), do: false

  defp health_status_badge_class("healthy"), do: "badge-success"
  defp health_status_badge_class("degraded"), do: "badge-warning"
  defp health_status_badge_class("unhealthy"), do: "badge-error"
  defp health_status_badge_class("unknown"), do: "badge-ghost"
  defp health_status_badge_class(_), do: "badge-ghost"

  defp health_status_label("healthy"), do: "Healthy"
  defp health_status_label("degraded"), do: "Degraded"
  defp health_status_label("unhealthy"), do: "Unhealthy"
  defp health_status_label("unknown"), do: "Unknown"
  defp health_status_label(nil), do: "Unknown"
  defp health_status_label(_), do: "Unknown"

  defp format_sync_error(:rate_limit_exceeded),
    do: "GitHub API rate limit exceeded. Try again later."

  defp format_sync_error(:not_found), do: "Repository or definitions path not found."
  defp format_sync_error({:unexpected_status, status}), do: "Unexpected HTTP status: #{status}"
  defp format_sync_error(reason) when is_binary(reason), do: reason
  defp format_sync_error(reason), do: inspect(reason)
end
