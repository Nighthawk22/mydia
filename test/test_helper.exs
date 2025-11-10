# Limit concurrent test execution for SQLite compatibility
# SQLite doesn't handle high concurrency well, even with WAL mode
# Using 1 concurrent case to avoid "Database busy" errors with SQLite
# Exclude external integration tests by default (require external services)
ExUnit.start(max_cases: 1, exclude: [:external])
Ecto.Adapters.SQL.Sandbox.mode(Mydia.Repo, :manual)

# Configure ExMachina
{:ok, _} = Application.ensure_all_started(:ex_machina)
