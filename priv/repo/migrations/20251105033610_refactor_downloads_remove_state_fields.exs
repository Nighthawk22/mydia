defmodule Mydia.Repo.Migrations.RefactorDownloadsRemoveStateFields do
  use Ecto.Migration

  def change do
    # SQLite doesn't support dropping columns, so we recreate the table
    # Remove state fields: status, progress, estimated_completion
    # Keep: completed_at and error_message for historical records

    execute(
      """
      CREATE TABLE downloads_new (
        id TEXT PRIMARY KEY NOT NULL,
        media_item_id TEXT REFERENCES media_items(id) ON DELETE CASCADE,
        episode_id TEXT REFERENCES episodes(id) ON DELETE CASCADE,
        indexer TEXT,
        title TEXT NOT NULL,
        download_url TEXT,
        download_client TEXT,
        download_client_id TEXT,
        completed_at TEXT,
        error_message TEXT,
        metadata TEXT,
        inserted_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
      """,
      "DROP TABLE IF EXISTS downloads_new"
    )

    execute(
      """
      INSERT INTO downloads_new (
        id, media_item_id, episode_id, indexer, title, download_url,
        download_client, download_client_id, completed_at, error_message,
        metadata, inserted_at, updated_at
      )
      SELECT
        id, media_item_id, episode_id, indexer, title, download_url,
        download_client, download_client_id, completed_at, error_message,
        metadata, inserted_at, updated_at
      FROM downloads
      """,
      ""
    )

    execute("DROP TABLE downloads", "")
    execute("ALTER TABLE downloads_new RENAME TO downloads", "")

    # Recreate indexes
    create index(:downloads, [:media_item_id])
    create index(:downloads, [:episode_id])
    create index(:downloads, [:inserted_at])
    create index(:downloads, [:download_client_id])
  end
end
