defmodule Mydia.Downloads.TorrentParserTest do
  use ExUnit.Case, async: true
  alias Mydia.Downloads.TorrentParser

  describe "parse/1 - movies" do
    test "parses standard movie torrent name with dots" do
      {:ok, info} = TorrentParser.parse("The.Matrix.1999.1080p.BluRay.x264-SPARKS")

      assert info.type == :movie
      assert info.title == "The Matrix"
      assert info.year == 1999
      assert info.quality == "1080p"
      assert info.source == "BluRay"
      assert info.codec == "x264"
      assert info.release_group == "SPARKS"
    end

    test "parses movie with spaces and brackets" do
      {:ok, info} = TorrentParser.parse("Inception (2010) 720p BluRay x264-YIFY")

      assert info.type == :movie
      assert info.title == "Inception"
      assert info.year == 2010
      assert info.quality == "720p"
      assert info.source == "BluRay"
      assert info.codec == "x264"
      assert info.release_group == "YIFY"
    end

    test "parses movie with WEB-DL source" do
      {:ok, info} = TorrentParser.parse("Dune.2021.2160p.WEB-DL.x265-EVO")

      assert info.type == :movie
      assert info.title == "Dune"
      assert info.year == 2021
      assert info.quality == "2160p"
      assert info.source == "WEB-DL"
      assert info.codec == "x265"
      assert info.release_group == "EVO"
    end

    test "parses movie with multiple words in title" do
      {:ok, info} = TorrentParser.parse("The.Lord.of.the.Rings.2001.1080p.BluRay.x264-GROUP")

      assert info.type == :movie
      assert info.title == "The Lord of the Rings"
      assert info.year == 2001
    end

    test "handles movie without release group" do
      {:ok, info} = TorrentParser.parse("Interstellar.2014.1080p.BluRay.x264")

      assert info.type == :movie
      assert info.title == "Interstellar"
      assert info.year == 2014
      assert info.release_group == nil
    end
  end

  describe "parse/1 - TV shows" do
    test "parses standard TV show with S01E01 format" do
      {:ok, info} = TorrentParser.parse("Breaking.Bad.S01E01.720p.HDTV.x264-CTU")

      assert info.type == :tv
      assert info.title == "Breaking Bad"
      assert info.season == 1
      assert info.episode == 1
      assert info.quality == "720p"
      assert info.source == "HDTV"
      assert info.codec == "x264"
      assert info.release_group == "CTU"
    end

    test "parses TV show with single digit season and episode" do
      {:ok, info} = TorrentParser.parse("Friends.S1E5.1080p.WEB-DL.x264-NTb")

      assert info.type == :tv
      assert info.title == "Friends"
      assert info.season == 1
      assert info.episode == 5
    end

    test "parses TV show with 1x01 format" do
      {:ok, info} = TorrentParser.parse("Game.of.Thrones.1x01.720p.HDTV.x264-CTU")

      assert info.type == :tv
      assert info.title == "Game of Thrones"
      assert info.season == 1
      assert info.episode == 1
    end

    test "parses TV show with multiple words in title" do
      {:ok, info} = TorrentParser.parse("The.Big.Bang.Theory.S10E15.1080p.WEB-DL.x264-RBB")

      assert info.type == :tv
      assert info.title == "The Big Bang Theory"
      assert info.season == 10
      assert info.episode == 15
    end

    test "handles TV show without release group" do
      {:ok, info} = TorrentParser.parse("Stranger.Things.S02E03.1080p.WEBRip.x265")

      assert info.type == :tv
      assert info.title == "Stranger Things"
      assert info.season == 2
      assert info.episode == 3
      assert info.release_group == nil
    end
  end

  describe "parse/1 - edge cases" do
    test "handles file extension in name" do
      {:ok, info} = TorrentParser.parse("The.Matrix.1999.1080p.BluRay.x264.mkv")

      assert info.type == :movie
      assert info.title == "The Matrix"
    end

    test "returns error for unparseable name" do
      assert {:error, :unable_to_parse} = TorrentParser.parse("random-file-name")
    end

    test "returns error for empty string" do
      assert {:error, :unable_to_parse} = TorrentParser.parse("")
    end
  end

  describe "parse/1 - quality detection" do
    test "detects 4K quality" do
      {:ok, info} = TorrentParser.parse("Movie.2020.4K.UHD.BluRay.x265-GRP")
      assert info.quality == "2160p"
    end

    test "detects 2160p quality" do
      {:ok, info} = TorrentParser.parse("Movie.2020.2160p.WEB-DL.x265-GRP")
      assert info.quality == "2160p"
    end

    test "detects SD quality" do
      {:ok, info} = TorrentParser.parse("Movie.2020.SD.DVDRip.x264-GRP")
      assert info.quality == "SD"
    end
  end

  describe "parse/1 - source detection" do
    test "detects various BluRay formats" do
      {:ok, info1} = TorrentParser.parse("Movie.2020.1080p.BluRay.x264-GRP")
      {:ok, info2} = TorrentParser.parse("Movie.2020.1080p.Blu-Ray.x264-GRP")
      {:ok, info3} = TorrentParser.parse("Movie.2020.1080p.BDRip.x264-GRP")
      {:ok, info4} = TorrentParser.parse("Movie.2020.1080p.BRRip.x264-GRP")

      assert info1.source == "BluRay"
      assert info2.source == "BluRay"
      assert info3.source == "BluRay"
      assert info4.source == "BluRay"
    end

    test "distinguishes between WEB-DL and WEBRip" do
      {:ok, info1} = TorrentParser.parse("Movie.2020.1080p.WEB-DL.x264-GRP")
      {:ok, info2} = TorrentParser.parse("Movie.2020.1080p.WEBRip.x264-GRP")

      assert info1.source == "WEB-DL"
      assert info2.source == "WEBRip"
    end
  end

  describe "parse/1 - codec detection" do
    test "detects x265/HEVC codecs" do
      {:ok, info1} = TorrentParser.parse("Movie.2020.1080p.BluRay.x265-GRP")
      {:ok, info2} = TorrentParser.parse("Movie.2020.1080p.BluRay.h265-GRP")
      {:ok, info3} = TorrentParser.parse("Movie.2020.1080p.BluRay.HEVC-GRP")

      assert info1.codec == "x265"
      assert info2.codec == "x265"
      assert info3.codec == "x265"
    end

    test "detects x264 codec" do
      {:ok, info} = TorrentParser.parse("Movie.2020.1080p.BluRay.x264-GRP")
      assert info.codec == "x264"
    end
  end
end
