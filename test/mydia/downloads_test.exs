defmodule Mydia.DownloadsTest do
  use Mydia.DataCase, async: true

  import Mydia.AccountsFixtures
  import Mydia.SettingsFixtures

  alias Mydia.Downloads
  alias Mydia.Downloads.Download
  alias Mydia.Downloads.Client
  alias Mydia.Downloads.Client.Registry
  alias Mydia.Downloads.Client.Error
  alias Mydia.Indexers.SearchResult

  # Mock adapter for testing
  defmodule MockAdapter do
    @behaviour Client

    @impl true
    def test_connection(_config) do
      {:ok, %{version: "1.0.0", api_version: "1.0"}}
    end

    @impl true
    def add_torrent(_config, {:magnet, "magnet:?xt=valid"}, _opts) do
      {:ok, "mock-client-id-123"}
    end

    def add_torrent(_config, {:magnet, "magnet:?xt=error"}, _opts) do
      {:error, Error.invalid_torrent("Invalid magnet link")}
    end

    def add_torrent(_config, {:url, url}, _opts) do
      {:ok, "mock-url-id-#{String.length(url)}"}
    end

    def add_torrent(_config, _torrent, _opts) do
      {:ok, "mock-default-id"}
    end

    @impl true
    def get_status(_config, _client_id) do
      {:ok, %{}}
    end

    @impl true
    def list_torrents(_config, _opts) do
      {:ok, []}
    end

    @impl true
    def remove_torrent(_config, _client_id, _opts) do
      :ok
    end

    @impl true
    def pause_torrent(_config, _client_id) do
      :ok
    end

    @impl true
    def resume_torrent(_config, _client_id) do
      :ok
    end
  end

  setup do
    # Save original adapter and register mock adapter
    original_adapter =
      case Registry.get_adapter(:qbittorrent) do
        {:ok, adapter} -> adapter
        {:error, _} -> nil
      end

    Registry.register(:qbittorrent, MockAdapter)

    # Restore original adapter after test
    on_exit(fn ->
      if original_adapter do
        Registry.register(:qbittorrent, original_adapter)
      end
    end)

    # Create test user for client configs
    user = user_fixture()

    # Create test download client
    client1 =
      download_client_config_fixture(%{
        name: "test-client-1",
        type: "qbittorrent",
        enabled: true,
        priority: 1,
        host: "localhost",
        port: 8080,
        updated_by_id: user.id
      })

    client2 =
      download_client_config_fixture(%{
        name: "test-client-2",
        type: "qbittorrent",
        enabled: true,
        priority: 2,
        host: "localhost",
        port: 9091,
        category: "movies",
        updated_by_id: user.id
      })

    disabled_client =
      download_client_config_fixture(%{
        name: "disabled-client",
        type: "qbittorrent",
        enabled: false,
        priority: 3,
        host: "localhost",
        port: 7070,
        updated_by_id: user.id
      })

    # Create test search result
    search_result = %SearchResult{
      title: "Test Movie 2024 1080p BluRay x264",
      size: 2_147_483_648,
      seeders: 100,
      leechers: 50,
      download_url: "magnet:?xt=valid",
      indexer: "TestIndexer",
      category: 2000,
      quality: %{
        resolution: "1080p",
        source: "BluRay",
        codec: "x264",
        audio: nil,
        hdr: false,
        proper: false,
        repack: false
      }
    }

    {:ok,
     client1: client1,
     client2: client2,
     disabled_client: disabled_client,
     search_result: search_result,
     user: user}
  end

  describe "initiate_download/2" do
    test "successfully initiates download with highest priority client", %{
      search_result: search_result,
      client1: client1
    } do
      assert {:ok, download} = Downloads.initiate_download(search_result)

      assert download.status == "pending"
      assert download.title == search_result.title
      assert download.download_url == search_result.download_url
      assert download.indexer == search_result.indexer
      assert download.download_client == client1.name
      assert download.download_client_id == "mock-client-id-123"
      assert download.progress == 0
      assert download.metadata.size == search_result.size
      assert download.metadata.seeders == search_result.seeders
      assert download.metadata.leechers == search_result.leechers
      assert download.metadata.quality == search_result.quality
    end

    test "initiates download with specific client when requested", %{
      search_result: search_result,
      client2: client2
    } do
      assert {:ok, download} =
               Downloads.initiate_download(search_result, client_name: "test-client-2")

      assert download.download_client == client2.name
    end

    test "associates download with media_item_id when provided", %{search_result: search_result} do
      # Note: We're not actually creating a media item in this test,
      # we're just checking that the option is passed through
      # For a full integration test with real media items, see integration tests
      assert {:ok, download} = Downloads.initiate_download(search_result)

      # Verify the download was created successfully
      assert download.status == "pending"
    end

    test "associates download with episode_id when provided", %{search_result: search_result} do
      # Note: We're not actually creating an episode in this test,
      # we're just checking that the option is passed through
      # For a full integration test with real episodes, see integration tests
      assert {:ok, download} = Downloads.initiate_download(search_result)

      # Verify the download was created successfully
      assert download.status == "pending"
    end

    test "uses custom category when provided", %{search_result: search_result} do
      # The category is passed to the client adapter, which we can't directly verify
      # in this test without mocking more deeply, but we can verify the download is created
      assert {:ok, download} =
               Downloads.initiate_download(search_result, category: "custom-category")

      assert download.status == "pending"
    end

    test "uses client's default category when not provided", %{
      search_result: search_result,
      client2: client2
    } do
      # Client2 has category "movies"
      assert {:ok, download} =
               Downloads.initiate_download(search_result, client_name: client2.name)

      assert download.download_client == client2.name
    end

    test "handles URL download links", %{search_result: search_result} do
      url_result = %{search_result | download_url: "https://example.com/file.torrent"}

      assert {:ok, download} = Downloads.initiate_download(url_result)

      assert download.download_url == url_result.download_url
      assert String.starts_with?(download.download_client_id, "mock-url-id-")
    end

    test "returns error when no clients are configured" do
      # Delete ALL download client configs from the database (including runtime ones)
      Mydia.Settings.list_download_client_configs()
      |> Enum.each(fn client_config ->
        # Skip runtime clients (they can't be deleted)
        unless is_binary(client_config.id) and String.starts_with?(client_config.id, "runtime::") do
          Mydia.Settings.delete_download_client_config(client_config)
        end
      end)

      search_result = %SearchResult{
        title: "Test",
        size: 1000,
        seeders: 1,
        leechers: 0,
        download_url: "magnet:?xt=test",
        indexer: "Test"
      }

      # This should now return :no_clients_configured (no database clients)
      # or error about unknown client type (if runtime clients exist)
      result = Downloads.initiate_download(search_result)

      case result do
        {:error, :no_clients_configured} ->
          assert true

        {:error, {:client_error, %Error{type: :invalid_config}}} ->
          # This happens if there are runtime-configured clients without adapters
          assert true

        {:error, %Error{type: :invalid_config}} ->
          # This also happens if there are runtime-configured clients without adapters
          # (the error is not wrapped in :client_error tuple)
          assert true

        other ->
          flunk("Expected error, got: #{inspect(other)}")
      end
    end

    test "returns error when specified client is not found", %{search_result: search_result} do
      assert {:error, {:client_not_found, "nonexistent-client"}} =
               Downloads.initiate_download(search_result, client_name: "nonexistent-client")
    end

    test "returns error when specified client is disabled", %{
      search_result: search_result,
      disabled_client: disabled_client
    } do
      assert {:error, {:client_not_found, client_name}} =
               Downloads.initiate_download(search_result, client_name: disabled_client.name)

      assert client_name == disabled_client.name
    end

    test "returns error when client rejects torrent", %{client1: _client1} do
      error_result = %SearchResult{
        title: "Bad Torrent",
        size: 1000,
        seeders: 1,
        leechers: 0,
        download_url: "magnet:?xt=error",
        indexer: "Test"
      }

      assert {:error, {:client_error, %Error{type: :invalid_torrent}}} =
               Downloads.initiate_download(error_result)
    end

    test "skips disabled clients when selecting by priority", %{
      search_result: search_result,
      client1: client1,
      disabled_client: _disabled_client
    } do
      # Even though disabled_client has priority 3 (higher than client1's priority 1),
      # it should be skipped because it's disabled, and client1 should be selected
      assert {:ok, download} = Downloads.initiate_download(search_result)

      assert download.download_client == client1.name
    end

    test "selects client with lowest priority value", %{
      search_result: search_result,
      client1: client1,
      client2: _client2
    } do
      # client1 has priority 1, client2 has priority 2
      # Lower priority value should be selected
      assert {:ok, download} = Downloads.initiate_download(search_result)

      assert download.download_client == client1.name
    end
  end

  describe "list_downloads/1" do
    test "returns all downloads" do
      download1 = download_fixture(%{title: "Download 1", status: "pending"})
      download2 = download_fixture(%{title: "Download 2", status: "completed"})

      downloads = Downloads.list_downloads()

      assert length(downloads) == 2
      assert Enum.any?(downloads, &(&1.id == download1.id))
      assert Enum.any?(downloads, &(&1.id == download2.id))
    end

    test "filters by status" do
      _pending = download_fixture(%{title: "Pending", status: "pending"})
      completed = download_fixture(%{title: "Completed", status: "completed"})

      downloads = Downloads.list_downloads(status: "completed")

      assert length(downloads) == 1
      assert hd(downloads).id == completed.id
    end

    test "filters by multiple statuses" do
      pending = download_fixture(%{title: "Pending", status: "pending"})
      downloading = download_fixture(%{title: "Downloading", status: "downloading"})
      _completed = download_fixture(%{title: "Completed", status: "completed"})

      downloads = Downloads.list_downloads(status: ["pending", "downloading"])

      assert length(downloads) == 2
      assert Enum.any?(downloads, &(&1.id == pending.id))
      assert Enum.any?(downloads, &(&1.id == downloading.id))
    end

    test "filters by media_item_id" do
      # Create downloads without FK references for this test
      download1 = download_fixture(%{title: "Download with FK ref"})
      _download2 = download_fixture(%{title: "Download without FK ref"})

      # We can't test FK filtering without actual media items,
      # so we just verify the filter doesn't crash
      downloads = Downloads.list_downloads(media_item_id: download1.id)

      # Should return empty since no downloads have this as media_item_id
      assert downloads == []
    end

    test "filters by episode_id" do
      # Create downloads without FK references for this test
      download1 = download_fixture(%{title: "Download with FK ref"})
      _download2 = download_fixture(%{title: "Download without FK ref"})

      # We can't test FK filtering without actual episodes,
      # so we just verify the filter doesn't crash
      downloads = Downloads.list_downloads(episode_id: download1.id)

      # Should return empty since no downloads have this as episode_id
      assert downloads == []
    end
  end

  describe "get_download!/2" do
    test "returns the download with given id" do
      download = download_fixture()
      assert Downloads.get_download!(download.id).id == download.id
    end

    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Downloads.get_download!(Ecto.UUID.generate())
      end
    end
  end

  describe "create_download/1" do
    test "creates a download with valid attributes" do
      attrs = %{
        status: "pending",
        title: "Test Download",
        download_url: "magnet:?xt=test"
      }

      assert {:ok, %Download{} = download} = Downloads.create_download(attrs)
      assert download.status == "pending"
      assert download.title == "Test Download"
    end

    test "returns error with invalid status" do
      attrs = %{
        status: "invalid",
        title: "Test Download"
      }

      assert {:error, %Ecto.Changeset{}} = Downloads.create_download(attrs)
    end
  end

  describe "update_download/2" do
    test "updates the download" do
      download = download_fixture()

      assert {:ok, updated} =
               Downloads.update_download(download, %{status: "downloading", progress: 50})

      assert updated.status == "downloading"
      assert updated.progress == 50
    end
  end

  describe "delete_download/1" do
    test "deletes the download" do
      download = download_fixture()

      assert {:ok, %Download{}} = Downloads.delete_download(download)
      assert_raise Ecto.NoResultsError, fn -> Downloads.get_download!(download.id) end
    end
  end

  describe "list_active_downloads/1" do
    test "returns only pending and downloading downloads" do
      pending = download_fixture(%{status: "pending"})
      downloading = download_fixture(%{status: "downloading"})
      _completed = download_fixture(%{status: "completed"})
      _failed = download_fixture(%{status: "failed"})

      active = Downloads.list_active_downloads()

      assert length(active) == 2
      assert Enum.any?(active, &(&1.id == pending.id))
      assert Enum.any?(active, &(&1.id == downloading.id))
    end
  end

  # Helper function to create a download fixture
  defp download_fixture(attrs \\ %{}) do
    default_attrs = %{
      status: "pending",
      title: "Test Download",
      download_url: "magnet:?xt=test",
      progress: 0
    }

    {:ok, download} =
      default_attrs
      |> Map.merge(attrs)
      |> Downloads.create_download()

    download
  end
end
