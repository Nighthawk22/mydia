defmodule Mydia.Downloads.TorrentParser do
  @moduledoc """
  Parses torrent names to extract structured media information.

  Handles common torrent naming patterns for movies and TV shows to extract:
  - Title
  - Year (for movies)
  - Season and episode numbers (for TV shows)
  - Quality/resolution
  - Release group

  ## Examples

      iex> parse("The.Matrix.1999.1080p.BluRay.x264-SPARKS")
      {:ok, %{
        type: :movie,
        title: "The Matrix",
        year: 1999,
        quality: "1080p",
        source: "BluRay",
        codec: "x264",
        release_group: "SPARKS"
      }}

      iex> parse("Breaking.Bad.S01E01.720p.HDTV.x264-CTU")
      {:ok, %{
        type: :tv,
        title: "Breaking Bad",
        season: 1,
        episode: 1,
        quality: "720p",
        source: "HDTV",
        codec: "x264",
        release_group: "CTU"
      }}
  """

  @doc """
  Parses a torrent name and returns structured information.

  Returns `{:ok, info_map}` on success, or `{:error, reason}` if parsing fails.
  """
  def parse(name) when is_binary(name) do
    name = clean_name(name)

    cond do
      # Try to parse as TV show (check for season/episode pattern)
      tv_info = parse_tv(name) ->
        {:ok, tv_info}

      # Try to parse as movie (check for year pattern)
      movie_info = parse_movie(name) ->
        {:ok, movie_info}

      # Unable to determine type
      true ->
        {:error, :unable_to_parse}
    end
  end

  ## Private Functions

  defp clean_name(name) do
    # Remove file extensions if present
    name
    |> String.replace(~r/\.(mkv|mp4|avi|mov|wmv|flv|webm)$/i, "")
    |> String.trim()
  end

  defp parse_tv(name) do
    # Match patterns like S01E01, S1E1, 1x01, etc.
    cond do
      # S01E01 or S1E1 format
      match =
          Regex.named_captures(
            ~r/^(?<title>.+?)[\s\.]S(?<season>\d{1,2})E(?<episode>\d{1,2})/i,
            name
          ) ->
        build_tv_info(match, name)

      # 1x01 format
      match =
          Regex.named_captures(
            ~r/^(?<title>.+?)[\s\.](?<season>\d{1,2})x(?<episode>\d{1,2})/i,
            name
          ) ->
        build_tv_info(match, name)

      true ->
        nil
    end
  end

  defp build_tv_info(match, full_name) do
    title = clean_title(match["title"])
    season = String.to_integer(match["season"])
    episode = String.to_integer(match["episode"])

    # Extract remaining parts after the episode marker
    remaining = extract_remaining_after_episode(full_name, match)

    %{
      type: :tv,
      title: title,
      season: season,
      episode: episode,
      quality: extract_quality(remaining),
      source: extract_source(remaining),
      codec: extract_codec(remaining),
      release_group: extract_release_group(remaining)
    }
  end

  defp parse_movie(name) do
    # Match patterns with year: Title (2020) or Title.2020
    case Regex.named_captures(
           ~r/^(?<title>.+?)[\s\.\(\[](?<year>19\d{2}|20\d{2})[\s\.\)\]]/i,
           name
         ) do
      nil ->
        nil

      match ->
        title = clean_title(match["title"])
        year = String.to_integer(match["year"])

        # Extract remaining parts after the year
        remaining = extract_remaining_after_year(name, match)

        %{
          type: :movie,
          title: title,
          year: year,
          quality: extract_quality(remaining),
          source: extract_source(remaining),
          codec: extract_codec(remaining),
          release_group: extract_release_group(remaining)
        }
    end
  end

  defp clean_title(title) do
    title
    |> String.replace(".", " ")
    |> String.replace("_", " ")
    |> String.trim()
    # Normalize multiple spaces
    |> String.replace(~r/\s+/, " ")
  end

  defp extract_remaining_after_episode(full_name, match) do
    # Find where the episode pattern ends
    pattern = "S#{match["season"]}E#{match["episode"]}"

    case String.split(full_name, pattern, parts: 2) do
      [_, remaining] -> remaining
      _ -> ""
    end
  end

  defp extract_remaining_after_year(full_name, match) do
    # Find where the year ends
    year = match["year"]

    case String.split(full_name, year, parts: 2) do
      [_, remaining] -> remaining
      _ -> ""
    end
  end

  defp extract_quality(text) do
    cond do
      Regex.match?(~r/2160p|4K/i, text) -> "2160p"
      Regex.match?(~r/1080p/i, text) -> "1080p"
      Regex.match?(~r/720p/i, text) -> "720p"
      Regex.match?(~r/480p/i, text) -> "480p"
      Regex.match?(~r/\bSD\b/i, text) -> "SD"
      true -> nil
    end
  end

  defp extract_source(text) do
    cond do
      Regex.match?(~r/BluRay|Blu-Ray|BDRip|BRRip/i, text) -> "BluRay"
      Regex.match?(~r/WEB-?DL|WEBDL/i, text) -> "WEB-DL"
      Regex.match?(~r/WEBRip|WEB-?Rip/i, text) -> "WEBRip"
      Regex.match?(~r/HDTV/i, text) -> "HDTV"
      Regex.match?(~r/DVDRip/i, text) -> "DVDRip"
      Regex.match?(~r/DVD/i, text) -> "DVD"
      true -> nil
    end
  end

  defp extract_codec(text) do
    cond do
      Regex.match?(~r/x265|h\.?265|HEVC/i, text) -> "x265"
      Regex.match?(~r/x264|h\.?264/i, text) -> "x264"
      Regex.match?(~r/XviD/i, text) -> "XviD"
      true -> nil
    end
  end

  defp extract_release_group(text) do
    # Release group is typically after a dash at the end
    # e.g., "-SPARKS" or "[SPARKS]"
    case Regex.run(~r/[-\[]([A-Z0-9]+)[\]\s]*$/i, text) do
      [_, group] -> group
      _ -> nil
    end
  end
end
