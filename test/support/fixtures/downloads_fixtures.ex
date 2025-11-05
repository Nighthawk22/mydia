defmodule Mydia.DownloadsFixtures do
  @moduledoc """
  This module defines test helpers for creating entities via the `Mydia.Downloads` context.
  """

  import Mydia.MediaFixtures

  @doc """
  Generate a download.
  """
  def download_fixture(attrs \\ %{}) do
    # Convert keyword list to map if needed
    attrs = Map.new(attrs)

    # Create a media item if not provided
    media_item_id =
      case Map.get(attrs, :media_item_id) do
        nil ->
          media_item = media_item_fixture()
          media_item.id

        id ->
          id
      end

    unique_id = System.unique_integer([:positive])

    {:ok, download} =
      attrs
      |> Enum.into(%{
        media_item_id: media_item_id,
        title: "Test Download #{unique_id}",
        indexer: "test-indexer",
        download_url: "magnet:?xt=urn:btih:test#{unique_id}",
        download_client: "test-client",
        download_client_id: "test-#{unique_id}",
        metadata: %{
          size: 1_000_000_000,
          seeders: 10,
          leechers: 5,
          quality: "1080p"
        }
      })
      |> Mydia.Downloads.create_download()

    download
  end
end
