defmodule Mydia.Repo.Migrations.CreateSubtitleProviders do
  use Ecto.Migration

  def change do
    create table(:subtitle_providers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id), null: false
      add :name, :string, null: false
      add :type, :string, null: false
      add :enabled, :boolean, default: true, null: false
      add :priority, :integer, default: 0, null: false

      # OpenSubtitles-specific fields (null for relay providers)
      add :username, :string
      add :password, :string
      add :api_key, :string

      # Quota tracking for OpenSubtitles providers
      add :quota_remaining, :integer
      add :quota_total, :integer
      add :quota_reset_at, :utc_datetime
      add :vip_status, :boolean, default: false

      timestamps(type: :utc_datetime)
    end

    # Unique constraint on user_id + name
    create unique_index(:subtitle_providers, [:user_id, :name])

    # Index for provider selection queries (enabled providers sorted by priority)
    create index(:subtitle_providers, [:user_id, :enabled, :priority])
  end
end
