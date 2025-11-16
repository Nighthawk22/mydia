defmodule Mydia.Repo.Migrations.AddImportRetryFieldsToDownloads do
  use Ecto.Migration

  def change do
    alter table(:downloads) do
      add :import_retry_count, :integer, default: 0
      add :import_last_error, :text
      add :import_next_retry_at, :utc_datetime
      add :import_failed_at, :utc_datetime
    end

    create index(:downloads, [:import_next_retry_at])
    create index(:downloads, [:import_failed_at])
  end
end
