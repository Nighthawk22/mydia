defmodule Mydia.Media.EpisodeStatusTest do
  use ExUnit.Case, async: true

  alias Mydia.Media.{Episode, EpisodeStatus}

  describe "get_episode_status/1" do
    test "returns :tba for episodes with nil air_date" do
      episode = %Episode{
        monitored: true,
        air_date: nil,
        media_files: [],
        downloads: []
      }

      assert EpisodeStatus.get_episode_status(episode) == :tba
    end

    test "returns :not_monitored for unmonitored episodes" do
      episode = %Episode{
        monitored: false,
        air_date: nil,
        media_files: [],
        downloads: []
      }

      assert EpisodeStatus.get_episode_status(episode) == :not_monitored
    end

    test "returns :downloaded for episodes with media files" do
      episode = %Episode{
        monitored: true,
        air_date: ~D[2024-01-01],
        media_files: [%{resolution: "1080p"}],
        downloads: []
      }

      assert EpisodeStatus.get_episode_status(episode) == :downloaded
    end

    test "returns :upcoming for episodes with future air dates" do
      future_date = Date.add(Date.utc_today(), 7)

      episode = %Episode{
        monitored: true,
        air_date: future_date,
        media_files: [],
        downloads: []
      }

      assert EpisodeStatus.get_episode_status(episode) == :upcoming
    end
  end

  describe "get_episode_status_with_downloads/1" do
    test "returns :tba for episodes with nil air_date" do
      episode = %Episode{
        monitored: true,
        air_date: nil,
        media_files: [],
        downloads: []
      }

      assert EpisodeStatus.get_episode_status_with_downloads(episode) == :tba
    end

    test "returns :not_monitored for unmonitored episodes regardless of air_date" do
      episode = %Episode{
        monitored: false,
        air_date: nil,
        media_files: [],
        downloads: []
      }

      assert EpisodeStatus.get_episode_status_with_downloads(episode) == :not_monitored
    end

    test "returns :downloaded for episodes with media files even with nil air_date" do
      episode = %Episode{
        monitored: true,
        air_date: nil,
        media_files: [%{resolution: "1080p"}],
        downloads: []
      }

      assert EpisodeStatus.get_episode_status_with_downloads(episode) == :downloaded
    end
  end

  describe "status UI helpers" do
    test "status_color/1 returns badge-warning for :tba" do
      assert EpisodeStatus.status_color(:tba) == "badge-warning"
    end

    test "status_icon/1 returns hero-question-mark-circle for :tba" do
      assert EpisodeStatus.status_icon(:tba) == "hero-question-mark-circle"
    end

    test "status_label/1 returns TBA for :tba" do
      assert EpisodeStatus.status_label(:tba) == "TBA"
    end

    test "status_color/1 returns badge-warning for :partial" do
      assert EpisodeStatus.status_color(:partial) == "badge-warning"
    end

    test "status_icon/1 returns hero-minus-circle for :partial" do
      assert EpisodeStatus.status_icon(:partial) == "hero-minus-circle"
    end

    test "status_label/1 returns Partial for :partial" do
      assert EpisodeStatus.status_label(:partial) == "Partial"
    end
  end

  describe "status_details/1" do
    test "returns 'Air date to be announced' for episodes with nil air_date" do
      episode = %Episode{
        monitored: true,
        air_date: nil,
        media_files: [],
        downloads: []
      }

      assert EpisodeStatus.status_details(episode) == "Air date to be announced"
    end

    test "returns 'Not Monitored' for unmonitored episodes" do
      episode = %Episode{
        monitored: false,
        air_date: nil,
        media_files: [],
        downloads: []
      }

      assert EpisodeStatus.status_details(episode) == "Not Monitored"
    end

    test "handles plain Download struct without progress field" do
      # Simulates a Download struct from database (no progress field)
      download = %Mydia.Downloads.Download{
        id: "test-id",
        title: "Test Download",
        completed_at: nil,
        error_message: nil
      }

      past_date = Date.add(Date.utc_today(), -1)

      episode = %Episode{
        monitored: true,
        air_date: past_date,
        media_files: [],
        downloads: [download]
      }

      # Should not crash and should return generic downloading message
      assert EpisodeStatus.status_details(episode) == "Downloading (1 active)"
    end

    test "handles enriched download map with progress field" do
      # Simulates an enriched download map from list_downloads_with_status
      download = %{
        id: "test-id",
        title: "Test Download",
        completed_at: nil,
        error_message: nil,
        progress: 42.5
      }

      past_date = Date.add(Date.utc_today(), -1)

      episode = %Episode{
        monitored: true,
        air_date: past_date,
        media_files: [],
        downloads: [download]
      }

      # Should display progress percentage
      assert EpisodeStatus.status_details(episode) == "Downloading (43%)"
    end

    test "handles multiple active downloads without progress" do
      download1 = %Mydia.Downloads.Download{
        id: "test-id-1",
        title: "Test Download 1",
        completed_at: nil,
        error_message: nil
      }

      download2 = %Mydia.Downloads.Download{
        id: "test-id-2",
        title: "Test Download 2",
        completed_at: nil,
        error_message: nil
      }

      past_date = Date.add(Date.utc_today(), -1)

      episode = %Episode{
        monitored: true,
        air_date: past_date,
        media_files: [],
        downloads: [download1, download2]
      }

      # Should return count of active downloads
      assert EpisodeStatus.status_details(episode) == "Downloading (2 active)"
    end
  end
end
