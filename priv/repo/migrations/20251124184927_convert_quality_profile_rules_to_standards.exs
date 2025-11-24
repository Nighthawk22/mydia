defmodule Mydia.Repo.Migrations.ConvertQualityProfileRulesToStandards do
  use Ecto.Migration
  import Ecto.Query

  def up do
    # Get all quality profiles with rules
    profiles =
      from(p in "quality_profiles",
        select: %{
          id: p.id,
          name: p.name,
          rules: p.rules,
          quality_standards: p.quality_standards,
          description: p.description
        }
      )
      |> Mydia.Repo.all()

    # Convert each profile
    Enum.each(profiles, fn profile ->
      # Skip if quality_standards already populated (idempotency)
      if is_nil(profile.quality_standards) || profile.quality_standards == %{} do
        convert_profile(profile)
      end
    end)
  end

  def down do
    # Rollback: convert quality_standards back to rules
    profiles =
      from(p in "quality_profiles",
        select: %{
          id: p.id,
          name: p.name,
          rules: p.rules,
          quality_standards: p.quality_standards,
          description: p.description
        }
      )
      |> Mydia.Repo.all()

    Enum.each(profiles, fn profile ->
      if profile.quality_standards && profile.quality_standards != %{} do
        rollback_profile(profile)
      end
    end)
  end

  defp convert_profile(profile) do
    # Decode rules if it's a JSON string
    rules =
      case profile.rules do
        nil -> %{}
        rules when is_binary(rules) -> Jason.decode!(rules)
        rules when is_map(rules) -> rules
        _ -> %{}
      end

    # Extract values from rules
    min_size_mb = get_in(rules, ["min_size_mb"])
    max_size_mb = get_in(rules, ["max_size_mb"])
    preferred_sources = get_in(rules, ["preferred_sources"]) || []
    rules_description = get_in(rules, ["description"])

    # Build quality_standards map
    quality_standards =
      %{}
      |> put_movie_sizes(min_size_mb, max_size_mb)
      |> put_episode_sizes(min_size_mb, max_size_mb)
      |> put_preferred_sources(preferred_sources)

    # Prepare updates - encode quality_standards as JSON for SQLite
    updates = %{quality_standards: Jason.encode!(quality_standards)}

    # Only update description if it's currently nil and rules has a description
    updates =
      if is_nil(profile.description) && rules_description do
        Map.put(updates, :description, rules_description)
      else
        updates
      end

    # Update the profile
    from(p in "quality_profiles", where: p.id == ^profile.id)
    |> Mydia.Repo.update_all(set: Map.to_list(updates))
  end

  defp rollback_profile(profile) do
    # Decode quality_standards if it's a JSON string
    standards =
      case profile.quality_standards do
        nil -> %{}
        standards when is_binary(standards) -> Jason.decode!(standards)
        standards when is_map(standards) -> standards
        _ -> %{}
      end

    # Extract values from quality_standards
    movie_min = get_in(standards, ["movie_min_size_mb"])
    movie_max = get_in(standards, ["movie_max_size_mb"])
    preferred_sources = get_in(standards, ["preferred_sources"]) || []

    # Build rules map using movie sizes as the base
    rules =
      %{}
      |> Map.put("min_size_mb", movie_min)
      |> Map.put("max_size_mb", movie_max)
      |> Map.put("preferred_sources", preferred_sources)
      |> Map.put("description", profile.description)

    # Update the profile - encode rules as JSON for SQLite
    from(p in "quality_profiles", where: p.id == ^profile.id)
    |> Mydia.Repo.update_all(set: [rules: Jason.encode!(rules)])
  end

  # Helper to add movie sizes to quality_standards
  defp put_movie_sizes(standards, min_size, max_size) do
    standards
    |> put_if_not_nil(:movie_min_size_mb, min_size)
    |> put_if_not_nil(:movie_max_size_mb, max_size)
  end

  # Helper to add episode sizes to quality_standards (50% of movie sizes)
  defp put_episode_sizes(standards, min_size, max_size) do
    standards
    |> put_if_not_nil(:episode_min_size_mb, scale_for_episode(min_size))
    |> put_if_not_nil(:episode_max_size_mb, scale_for_episode(max_size))
  end

  # Helper to add preferred_sources to quality_standards
  defp put_preferred_sources(standards, sources) when is_list(sources) and sources != [] do
    Map.put(standards, :preferred_sources, sources)
  end

  defp put_preferred_sources(standards, _sources), do: standards

  # Helper to scale movie size to episode size (50%)
  defp scale_for_episode(nil), do: nil
  defp scale_for_episode(size) when is_number(size), do: div(size, 2)
  defp scale_for_episode(_), do: nil

  # Helper to conditionally put a value in a map
  defp put_if_not_nil(map, _key, nil), do: map
  defp put_if_not_nil(map, key, value), do: Map.put(map, key, value)
end
