defmodule Mydia.Indexers.CategoryMappingTest do
  use ExUnit.Case, async: true

  alias Mydia.Indexers.CategoryMapping

  describe "categories_for_type/1" do
    test "returns movie categories for :movies type" do
      categories = CategoryMapping.categories_for_type(:movies)

      assert is_list(categories)
      assert 2000 in categories
      assert 2040 in categories
      assert 2045 in categories
      # Should not include TV or other types
      refute 5000 in categories
      refute 3000 in categories
    end

    test "returns TV categories for :series type" do
      categories = CategoryMapping.categories_for_type(:series)

      assert is_list(categories)
      assert 5000 in categories
      assert 5040 in categories
      assert 5070 in categories
      # Should not include movies
      refute 2000 in categories
    end

    test "returns audio categories for :music type" do
      categories = CategoryMapping.categories_for_type(:music)

      assert is_list(categories)
      assert 3000 in categories
      assert 3010 in categories
      assert 3040 in categories
      # Should not include video categories
      refute 2000 in categories
      refute 5000 in categories
    end

    test "returns book categories for :books type" do
      categories = CategoryMapping.categories_for_type(:books)

      assert is_list(categories)
      assert 7000 in categories
      assert 7020 in categories
      assert 7030 in categories
      # Should not include other types
      refute 2000 in categories
      refute 3000 in categories
    end

    test "returns adult categories for :adult type" do
      categories = CategoryMapping.categories_for_type(:adult)

      assert is_list(categories)
      assert 6000 in categories
      assert 6040 in categories
      # Should not include other types
      refute 2000 in categories
      refute 5000 in categories
    end

    test "returns combined movies and TV for :mixed type" do
      categories = CategoryMapping.categories_for_type(:mixed)
      movie_categories = CategoryMapping.categories_for_type(:movies)
      tv_categories = CategoryMapping.categories_for_type(:series)

      # Should include both movie and TV categories
      assert 2000 in categories
      assert 5000 in categories

      # Should be union of movies and series
      for cat <- movie_categories, do: assert(cat in categories)
      for cat <- tv_categories, do: assert(cat in categories)
    end

    test "returns empty list for unknown type" do
      assert CategoryMapping.categories_for_type(:unknown) == []
      assert CategoryMapping.categories_for_type(:invalid) == []
    end
  end

  describe "parent_category/1" do
    test "returns parent category ID for each library type" do
      assert CategoryMapping.parent_category(:movies) == 2000
      assert CategoryMapping.parent_category(:series) == 5000
      assert CategoryMapping.parent_category(:music) == 3000
      assert CategoryMapping.parent_category(:books) == 7000
      assert CategoryMapping.parent_category(:adult) == 6000
    end

    test "returns nil for mixed type" do
      assert CategoryMapping.parent_category(:mixed) == nil
    end

    test "returns nil for unknown type" do
      assert CategoryMapping.parent_category(:unknown) == nil
    end
  end

  describe "category_name/1" do
    test "returns correct names for movie categories" do
      assert CategoryMapping.category_name(2000) == "Movies"
      assert CategoryMapping.category_name(2040) == "Movies/HD"
      assert CategoryMapping.category_name(2045) == "Movies/UHD"
    end

    test "returns correct names for TV categories" do
      assert CategoryMapping.category_name(5000) == "TV"
      assert CategoryMapping.category_name(5040) == "TV/HD"
      assert CategoryMapping.category_name(5070) == "TV/Anime"
    end

    test "returns correct names for audio categories" do
      assert CategoryMapping.category_name(3000) == "Audio"
      assert CategoryMapping.category_name(3010) == "Audio/MP3"
      assert CategoryMapping.category_name(3040) == "Audio/Lossless"
    end

    test "returns correct names for book categories" do
      assert CategoryMapping.category_name(7000) == "Books"
      assert CategoryMapping.category_name(7020) == "Books/EBook"
      assert CategoryMapping.category_name(7030) == "Books/Comics"
    end

    test "returns correct names for adult categories" do
      assert CategoryMapping.category_name(6000) == "XXX"
      assert CategoryMapping.category_name(6040) == "XXX/x264"
    end

    test "returns Unknown for unrecognized category IDs" do
      assert CategoryMapping.category_name(9999) == "Unknown (9999)"
    end
  end

  describe "category_matches_type?/2" do
    test "correctly identifies movie categories" do
      assert CategoryMapping.category_matches_type?(2000, :movies)
      assert CategoryMapping.category_matches_type?(2040, :movies)
      refute CategoryMapping.category_matches_type?(5000, :movies)
      refute CategoryMapping.category_matches_type?(3000, :movies)
    end

    test "correctly identifies TV categories" do
      assert CategoryMapping.category_matches_type?(5000, :series)
      assert CategoryMapping.category_matches_type?(5070, :series)
      refute CategoryMapping.category_matches_type?(2000, :series)
    end

    test "correctly identifies music categories" do
      assert CategoryMapping.category_matches_type?(3000, :music)
      assert CategoryMapping.category_matches_type?(3040, :music)
      refute CategoryMapping.category_matches_type?(2000, :music)
    end
  end

  describe "type_for_category/1" do
    test "returns correct type for category ranges" do
      # Movies: 2000-2999
      assert CategoryMapping.type_for_category(2000) == :movies
      assert CategoryMapping.type_for_category(2500) == :movies
      assert CategoryMapping.type_for_category(2999) == :movies

      # Audio: 3000-3999
      assert CategoryMapping.type_for_category(3000) == :music
      assert CategoryMapping.type_for_category(3500) == :music

      # TV: 5000-5999
      assert CategoryMapping.type_for_category(5000) == :series
      assert CategoryMapping.type_for_category(5999) == :series

      # Adult: 6000-6999
      assert CategoryMapping.type_for_category(6000) == :adult
      assert CategoryMapping.type_for_category(6500) == :adult

      # Books: 7000-7999
      assert CategoryMapping.type_for_category(7000) == :books
      assert CategoryMapping.type_for_category(7999) == :books
    end

    test "returns :other for unknown ranges" do
      assert CategoryMapping.type_for_category(1000) == :other
      assert CategoryMapping.type_for_category(4000) == :other
      assert CategoryMapping.type_for_category(8000) == :other
      assert CategoryMapping.type_for_category(9000) == :other
    end
  end

  describe "all_categories/0" do
    test "returns list of all categories with metadata" do
      all = CategoryMapping.all_categories()

      assert is_list(all)
      assert length(all) > 0

      # Each entry should have id, name, and type
      for category <- all do
        assert is_map(category)
        assert is_integer(category.id)
        assert is_binary(category.name)
        assert is_atom(category.type)
      end
    end

    test "includes categories for all library types" do
      all = CategoryMapping.all_categories()
      types = Enum.map(all, & &1.type) |> Enum.uniq()

      assert :movies in types
      assert :series in types
      assert :music in types
      assert :books in types
      assert :adult in types
    end
  end
end
