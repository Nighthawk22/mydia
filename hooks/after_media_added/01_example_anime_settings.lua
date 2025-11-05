-- Example hook: Anime Settings Auto-Adjuster
--
-- This hook automatically detects anime TV shows and adjusts their settings
-- for optimal indexing and quality preferences.
--
-- Author: Mydia Team
-- Version: 1.0.0

function execute(event_data)
  -- Access the media item from event data
  local media = event_data.data.media_item

  -- Only process TV shows
  if media.type ~= "tv_show" then
    return {
      modified = false,
      message = "Skipped: not a TV show"
    }
  end

  -- Check if the title contains anime-related keywords
  local title_lower = string.lower(media.title)
  local is_anime = string.find(title_lower, "anime") ~= nil
                or string.find(title_lower, "attack on titan") ~= nil
                or string.find(title_lower, "naruto") ~= nil
                or string.find(title_lower, "one piece") ~= nil

  if not is_anime then
    return {
      modified = false,
      message = "Skipped: not detected as anime"
    }
  end

  -- Log that we detected an anime
  log.info("Detected anime TV show: " .. media.title)

  -- Return modifications to apply
  return {
    modified = true,
    changes = {
      data = {
        media_item = {
          -- Example: adjust quality profile
          quality_profile = "Anime 1080p",
          -- Example: preferred release groups
          preferred_release_groups = {"SubsPlease", "Erai-raws", "HorribleSubs"}
        }
      }
    },
    message = "Applied anime-specific settings to " .. media.title
  }
end

-- The execute function is called with the event data
-- Return value must be a table with:
--   - modified: boolean (true if changes were made)
--   - changes: table (nested structure with changes to apply)
--   - message: string (optional, for logging)
return execute(event)
