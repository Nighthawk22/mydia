defmodule Mydia.Repo.Migrations.MakeMediaFilesPathNullable do
  @moduledoc """
  Make the `path` column nullable in `media_files` table.

  The `path` field is deprecated in favor of `relative_path` + `library_path_id`.
  This migration allows new media files to be created without an absolute path.
  """

  use Ecto.Migration

  def up do
    # SQLite doesn't support ALTER COLUMN, so we need to recreate the table
    execute """
    CREATE TABLE media_files_new (
      id TEXT PRIMARY KEY NOT NULL,
      media_item_id TEXT REFERENCES media_items(id) ON DELETE CASCADE,
      episode_id TEXT REFERENCES episodes(id) ON DELETE CASCADE,
      path TEXT,
      size INTEGER,
      quality_profile_id TEXT REFERENCES quality_profiles(id),
      resolution TEXT,
      codec TEXT,
      hdr_format TEXT,
      audio_codec TEXT,
      bitrate INTEGER,
      verified_at TEXT,
      metadata TEXT,
      relative_path TEXT,
      library_path_id TEXT REFERENCES library_paths(id) ON DELETE CASCADE,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      CHECK(
        (media_item_id IS NOT NULL AND episode_id IS NULL) OR
        (media_item_id IS NULL AND episode_id IS NOT NULL)
      )
    )
    """

    # Copy all data from old table to new table
    execute """
    INSERT INTO media_files_new
    SELECT id, media_item_id, episode_id, path, size, quality_profile_id,
           resolution, codec, hdr_format, audio_codec, bitrate, verified_at,
           metadata, relative_path, library_path_id, inserted_at, updated_at
    FROM media_files
    """

    # Drop old table
    execute "DROP TABLE media_files"

    # Rename new table to original name
    execute "ALTER TABLE media_files_new RENAME TO media_files"

    # Recreate indexes
    create index(:media_files, [:media_item_id])
    create index(:media_files, [:episode_id])
    create index(:media_files, [:library_path_id])
  end

  def down do
    # Rollback: Recreate table with NOT NULL constraint on path
    # Note: This will fail if there are any NULL paths in the data
    execute """
    CREATE TABLE media_files_new (
      id TEXT PRIMARY KEY NOT NULL,
      media_item_id TEXT REFERENCES media_items(id) ON DELETE CASCADE,
      episode_id TEXT REFERENCES episodes(id) ON DELETE CASCADE,
      path TEXT NOT NULL UNIQUE,
      size INTEGER,
      quality_profile_id TEXT REFERENCES quality_profiles(id),
      resolution TEXT,
      codec TEXT,
      hdr_format TEXT,
      audio_codec TEXT,
      bitrate INTEGER,
      verified_at TEXT,
      metadata TEXT,
      relative_path TEXT,
      library_path_id TEXT REFERENCES library_paths(id) ON DELETE CASCADE,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      CHECK(
        (media_item_id IS NOT NULL AND episode_id IS NULL) OR
        (media_item_id IS NULL AND episode_id IS NOT NULL)
      )
    )
    """

    execute """
    INSERT INTO media_files_new
    SELECT id, media_item_id, episode_id, path, size, quality_profile_id,
           resolution, codec, hdr_format, audio_codec, bitrate, verified_at,
           metadata, relative_path, library_path_id, inserted_at, updated_at
    FROM media_files
    """

    execute "DROP TABLE media_files"
    execute "ALTER TABLE media_files_new RENAME TO media_files"

    create index(:media_files, [:media_item_id])
    create index(:media_files, [:episode_id])
    create index(:media_files, [:library_path_id])
  end
end
