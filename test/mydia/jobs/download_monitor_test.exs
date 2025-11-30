defmodule Mydia.Jobs.DownloadMonitorTest do
  use Mydia.DataCase, async: true
  use Oban.Testing, repo: Mydia.Repo

  alias Mydia.Jobs.DownloadMonitor
  alias Mydia.Downloads
  import Mydia.MediaFixtures
  import Mydia.DownloadsFixtures

  describe "perform/1" do
    test "successfully monitors downloads with no active downloads" do
      setup_runtime_config([])
      assert :ok = perform_job(DownloadMonitor, %{})
    end

    test "handles no configured download clients gracefully" do
      setup_runtime_config([])

      # Create an active download
      media_item = media_item_fixture()
      download_fixture(%{media_item_id: media_item.id})

      assert :ok = perform_job(DownloadMonitor, %{})
    end

    test "successfully monitors active downloads" do
      setup_runtime_config([build_test_client_config()])
      media_item = media_item_fixture()

      # Create downloads with different completion states
      download_fixture(%{media_item_id: media_item.id})
      download_fixture(%{media_item_id: media_item.id})
      download_fixture(%{media_item_id: media_item.id, completed_at: DateTime.utc_now()})

      assert :ok = perform_job(DownloadMonitor, %{})
    end

    test "processes active and completed downloads" do
      setup_runtime_config([build_test_client_config()])
      media_item = media_item_fixture()

      # Create active downloads (will be marked missing since they don't exist in client)
      active1 = download_fixture(%{media_item_id: media_item.id})
      active2 = download_fixture(%{media_item_id: media_item.id})

      # Create completed and failed downloads (will be kept)
      completed =
        download_fixture(%{media_item_id: media_item.id, completed_at: DateTime.utc_now()})

      failed = download_fixture(%{media_item_id: media_item.id, error_message: "Failed"})

      # Job should complete successfully
      assert :ok = perform_job(DownloadMonitor, %{})

      # Active downloads should be marked with error_message (preserved for Issues tab)
      # Note: "status" is calculated dynamically, but error_message persists
      updated_active1 = Downloads.get_download!(active1.id)
      updated_active2 = Downloads.get_download!(active2.id)
      assert updated_active1.error_message =~ "Removed from download client"
      assert updated_active2.error_message =~ "Removed from download client"

      # Completed and failed downloads should still exist
      assert Downloads.get_download!(completed.id)
      assert Downloads.get_download!(failed.id)
    end

    test "marks downloads without an assigned client as missing" do
      setup_runtime_config([build_test_client_config()])
      media_item = media_item_fixture()

      # Create download without a download_client (will be marked as missing)
      download =
        download_fixture(%{
          media_item_id: media_item.id,
          download_client: nil
        })

      assert :ok = perform_job(DownloadMonitor, %{})

      # Download should have error_message set (preserved for Issues tab)
      updated = Downloads.get_download!(download.id)
      assert updated.error_message =~ "Removed from download client"
    end

    test "marks downloads with non-existent client as missing" do
      setup_runtime_config([build_test_client_config()])
      media_item = media_item_fixture()

      # Create download with a client that doesn't exist in config
      download =
        download_fixture(%{
          media_item_id: media_item.id,
          download_client: "NonExistentClient",
          download_client_id: "test123"
        })

      assert :ok = perform_job(DownloadMonitor, %{})

      # Download should have error_message set (preserved for Issues tab)
      updated = Downloads.get_download!(download.id)
      assert updated.error_message =~ "NonExistentClient"
    end

    test "processes multiple downloads in a single run" do
      setup_runtime_config([build_test_client_config()])
      media_item = media_item_fixture()

      # Create multiple downloads (will be marked missing since they don't exist in client)
      d1 =
        download_fixture(%{
          media_item_id: media_item.id,
          title: "Download 1"
        })

      d2 =
        download_fixture(%{
          media_item_id: media_item.id,
          title: "Download 2"
        })

      d3 = download_fixture(%{media_item_id: media_item.id, title: "Download 3"})

      # Should process all downloads without crashing
      assert :ok = perform_job(DownloadMonitor, %{})

      # All downloads should have error_message set (preserved for Issues tab)
      assert Downloads.get_download!(d1.id).error_message =~ "Removed from download client"
      assert Downloads.get_download!(d2.id).error_message =~ "Removed from download client"
      assert Downloads.get_download!(d3.id).error_message =~ "Removed from download client"
    end

    test "marks downloads from disabled clients as missing" do
      # Configure a disabled client
      disabled_client = %{
        build_test_client_config()
        | name: "DisabledClient",
          enabled: false
      }

      setup_runtime_config([disabled_client])
      media_item = media_item_fixture()

      download =
        download_fixture(%{
          media_item_id: media_item.id,
          download_client: "DisabledClient",
          download_client_id: "test123"
        })

      assert :ok = perform_job(DownloadMonitor, %{})

      # Download should have error_message set since disabled clients are not queried
      updated = Downloads.get_download!(download.id)
      assert updated.error_message =~ "DisabledClient"
    end

    test "sorts download clients by priority" do
      # Configure multiple clients with different priorities
      client1 = %{build_test_client_config() | name: "Client1", priority: 3}
      client2 = %{build_test_client_config() | name: "Client2", priority: 1}
      client3 = %{build_test_client_config() | name: "Client3", priority: 2}

      setup_runtime_config([client1, client2, client3])

      # Job should complete successfully with clients sorted by priority
      assert :ok = perform_job(DownloadMonitor, %{})
    end

    test "handles downloads for different client types" do
      setup_runtime_config([
        build_test_client_config(%{name: "qBit", type: :qbittorrent}),
        build_test_client_config(%{name: "Trans", type: :transmission})
      ])

      media_item = media_item_fixture()

      download_fixture(%{
        media_item_id: media_item.id,
        download_client: "qBit",
        download_client_id: "hash1"
      })

      download_fixture(%{
        media_item_id: media_item.id,
        download_client: "Trans",
        download_client_id: "id2"
      })

      assert :ok = perform_job(DownloadMonitor, %{})
    end
  end

  describe "missing download detection" do
    test "marks downloads that no longer exist in any client as missing" do
      # Setup with no actual clients (simulates missing downloads)
      setup_runtime_config([])

      media_item = media_item_fixture()

      # Create a download that exists in DB but not in any client
      download =
        download_fixture(%{
          media_item_id: media_item.id,
          download_client: "test-client",
          download_client_id: "missing-123"
        })

      # Verify download exists before job runs
      assert Downloads.get_download!(download.id)

      # Run the job
      assert :ok = perform_job(DownloadMonitor, %{})

      # Download should have error_message set (preserved for Issues tab)
      updated = Downloads.get_download!(download.id)
      assert updated.error_message =~ "Removed from download client"
      assert updated.error_message =~ "test-client"
    end

    test "does not remove downloads that are already completed" do
      setup_runtime_config([])

      media_item = media_item_fixture()

      # Create a completed download
      download =
        download_fixture(%{
          media_item_id: media_item.id,
          completed_at: DateTime.utc_now()
        })

      # Run the job
      assert :ok = perform_job(DownloadMonitor, %{})

      # Completed download should still exist (status will be "completed")
      assert Downloads.get_download!(download.id)
    end

    test "does not remove downloads that have error messages" do
      setup_runtime_config([])

      media_item = media_item_fixture()

      # Create a failed download
      download =
        download_fixture(%{
          media_item_id: media_item.id,
          error_message: "Download failed"
        })

      # Run the job
      assert :ok = perform_job(DownloadMonitor, %{})

      # Failed download should still exist (status will be "failed")
      assert Downloads.get_download!(download.id)
    end

    test "marks multiple missing downloads in a single run" do
      setup_runtime_config([])

      media_item = media_item_fixture()

      # Create multiple downloads that don't exist in any client
      download1 =
        download_fixture(%{
          media_item_id: media_item.id,
          download_client: "test-client",
          download_client_id: "missing-1"
        })

      download2 =
        download_fixture(%{
          media_item_id: media_item.id,
          download_client: "test-client",
          download_client_id: "missing-2"
        })

      download3 =
        download_fixture(%{
          media_item_id: media_item.id,
          download_client: "test-client",
          download_client_id: "missing-3"
        })

      # Run the job
      assert :ok = perform_job(DownloadMonitor, %{})

      # All missing downloads should have error_message set (preserved for Issues tab)
      assert Downloads.get_download!(download1.id).error_message =~ "Removed from download client"
      assert Downloads.get_download!(download2.id).error_message =~ "Removed from download client"
      assert Downloads.get_download!(download3.id).error_message =~ "Removed from download client"
    end

    test "handles mix of missing, active, and completed downloads" do
      setup_runtime_config([])

      media_item = media_item_fixture()

      # Create a missing download (will be marked missing)
      missing_download =
        download_fixture(%{
          media_item_id: media_item.id,
          title: "Missing Download"
        })

      # Create a completed download (will be kept)
      completed_download =
        download_fixture(%{
          media_item_id: media_item.id,
          title: "Completed Download",
          completed_at: DateTime.utc_now()
        })

      # Create a failed download (will be kept)
      failed_download =
        download_fixture(%{
          media_item_id: media_item.id,
          title: "Failed Download",
          error_message: "Download failed in client"
        })

      # Run the job
      assert :ok = perform_job(DownloadMonitor, %{})

      # The missing download should have error_message set (preserved for Issues tab)
      updated_missing = Downloads.get_download!(missing_download.id)
      assert updated_missing.error_message =~ "Removed from download client"

      # Completed and failed downloads should still exist unchanged
      assert Downloads.get_download!(completed_download.id)
      assert Downloads.get_download!(failed_download.id)
    end

    test "broadcasts download update when marking missing download" do
      setup_runtime_config([])

      media_item = media_item_fixture()

      _download =
        download_fixture(%{
          media_item_id: media_item.id
        })

      # Subscribe to download updates
      Phoenix.PubSub.subscribe(Mydia.PubSub, "downloads")

      # Run the job
      assert :ok = perform_job(DownloadMonitor, %{})

      # Should receive update notification
      assert_received {:download_updated, _download_id}
    end
  end

  ## Helper Functions

  defp setup_runtime_config(download_clients) do
    config = %Mydia.Config.Schema{
      server: %Mydia.Config.Schema.Server{},
      database: %Mydia.Config.Schema.Database{},
      auth: %Mydia.Config.Schema.Auth{},
      media: %Mydia.Config.Schema.Media{},
      downloads: %Mydia.Config.Schema.Downloads{},
      logging: %Mydia.Config.Schema.Logging{},
      oban: %Mydia.Config.Schema.Oban{},
      download_clients: download_clients
    }

    Application.put_env(:mydia, :runtime_config, config)
  end

  defp build_test_client_config(overrides \\ %{}) do
    defaults = %{
      name: "TestClient",
      type: :qbittorrent,
      enabled: true,
      priority: 1,
      host: "localhost",
      port: 8080,
      username: "admin",
      password: "admin",
      use_ssl: false,
      url_base: nil,
      category: nil,
      download_directory: nil
    }

    struct!(Mydia.Config.Schema.DownloadClient, Map.merge(defaults, overrides))
  end
end
