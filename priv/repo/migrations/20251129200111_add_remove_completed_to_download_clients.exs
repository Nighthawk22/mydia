defmodule Mydia.Repo.Migrations.AddRemoveCompletedToDownloadClients do
  use Ecto.Migration

  def change do
    alter table(:download_client_configs) do
      add :remove_completed, :boolean, default: false
    end
  end
end
