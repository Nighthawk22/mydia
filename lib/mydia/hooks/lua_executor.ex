defmodule Mydia.Hooks.LuaExecutor do
  @moduledoc """
  Executes Lua hooks using Luerl in a sandboxed environment.
  """

  require Logger

  @doc """
  Execute a Lua script file with the given event data.

  Returns `{:ok, result}` with the hook result, or `{:error, reason}`.
  """
  def execute_file(path, event_data, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 5_000)

    case File.read(path) do
      {:ok, script} ->
        execute_script(script, event_data, timeout)

      {:error, reason} ->
        {:error, {:file_read_error, reason}}
    end
  end

  @doc """
  Execute a Lua script string with the given event data.
  """
  def execute_script(script, event_data, timeout) do
    task =
      Task.async(fn ->
        try do
          run_lua_script(script, event_data)
        rescue
          e -> {:error, {:lua_error, Exception.message(e)}}
        end
      end)

    case Task.yield(task, timeout) || Task.shutdown(task) do
      {:ok, result} ->
        result

      nil ->
        Logger.warning("Lua script execution timed out after #{timeout}ms")
        {:error, :timeout}
    end
  end

  # Private Functions

  defp run_lua_script(script, event_data) do
    # Initialize Luerl state
    state = Luerl.init()

    # Set up safe environment
    state = setup_safe_environment(state, event_data)

    # Execute the script
    case Luerl.do(state, script) do
      {[result | _], _state} ->
        # Luerl returns results, parse them
        parse_lua_result(result)

      {[], _state} ->
        # Script returned nothing, assume no modifications
        {:ok, %{modified: false}}

      {:error, reason, _state} ->
        {:error, {:lua_execution_error, reason}}
    end
  end

  defp setup_safe_environment(state, event_data) do
    # Convert event data to Lua-friendly format using Luerl.encode
    lua_event = Luerl.encode(state, event_data)

    # Set global 'event' variable
    state = Luerl.set_table_keys(state, [:event], lua_event)

    # Set global 'context' variable
    lua_context = Luerl.encode(state, event_data[:context] || %{})
    state = Luerl.set_table_keys(state, [:context], lua_context)

    # Add helper functions
    state = add_helper_functions(state)

    state
  end

  defp add_helper_functions(state) do
    # Add a simple log function
    log_fn = fn [message | _], lua_state ->
      IO.puts("Hook log: #{message}")
      {[], lua_state}
    end

    state = Luerl.set_table_keys(state, [:log, :info], log_fn)
    state = Luerl.set_table_keys(state, [:log, :warn], log_fn)
    state = Luerl.set_table_keys(state, [:log, :error], log_fn)

    state
  end

  defp parse_lua_result(lua_table) when is_list(lua_table) do
    # Convert Lua table to Elixir map using custom decoder
    # Luerl returns tables as lists of tuples
    result = lua_to_elixir(lua_table)

    if is_map(result) do
      {:ok, result}
    else
      {:error, {:invalid_result_format, "Hook must return a table"}}
    end
  end

  defp parse_lua_result(_), do: {:error, {:invalid_result_format, "Hook must return a table"}}

  defp lua_to_elixir(data) when is_list(data) do
    # Check if it's a Lua array (numeric keys) or table (string keys)
    if Enum.all?(data, fn {k, _v} -> is_number(k) end) do
      # Lua array -> Elixir list
      data
      |> Enum.sort_by(fn {k, _v} -> k end)
      |> Enum.map(fn {_k, v} -> lua_to_elixir(v) end)
    else
      # Lua table -> Elixir map
      data
      |> Enum.map(fn {k, v} ->
        key = if is_binary(k), do: String.to_atom(k), else: k
        {key, lua_to_elixir(v)}
      end)
      |> Map.new()
    end
  end

  defp lua_to_elixir(data), do: data
end
