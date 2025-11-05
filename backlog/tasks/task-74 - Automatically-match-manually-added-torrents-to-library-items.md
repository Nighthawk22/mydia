---
id: task-74
title: Automatically match manually-added torrents to library items
status: To Do
assignee: []
created_date: '2025-11-05 15:24'
updated_date: '2025-11-05 15:43'
labels:
  - automation
  - downloads
  - matching
  - import
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Enable Mydia to automatically detect and match torrents that users manually add to download clients (Transmission, qBittorrent, etc.) with items already in their library. This provides a hybrid workflow where users can browse torrent sites themselves but still benefit from Mydia's automatic import and organization.

## User Scenario

1. User adds "The Matrix (1999)" to their Mydia library
2. User browses a torrent site and manually adds a "The.Matrix.1999.1080p.BluRay.x264" torrent to Transmission
3. Mydia detects the new torrent in Transmission
4. Mydia parses the torrent name and matches it to "The Matrix" in the library
5. When the download completes, Mydia automatically imports it to the correct library location

## User Value

- **Flexibility**: Users can leverage specialized torrent sites, trackers, or sources not available through indexers
- **Control**: Users maintain manual selection while still getting automatic organization
- **Convenience**: No need to manually import files after downloading
- **Hybrid workflow**: Best of both worlds - manual search with automatic import

## Implementation Considerations

This feature requires:
- Periodic polling of download clients to detect new torrents not tracked in Mydia's database
- Title parsing to extract movie/show name, year, season/episode, quality, etc.
- Fuzzy matching algorithm to link parsed titles to library items
- Creating download records for matched torrents to enable automatic import
- Handling edge cases where multiple library items could match
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Download monitor job detects torrents in download clients that don't have corresponding records in Mydia's database
- [x] #2 Torrent names are parsed to extract media title, year, season/episode numbers, quality, and release group
- [x] #3 Parsed information is used to search for matching items in the user's library
- [x] #4 When a confident match is found (movie or TV episode), a download record is created linking the torrent to the library item
- [x] #5 Manually-added torrents are automatically imported to the library when they complete downloading
- [ ] #6 System handles ambiguous matches gracefully (multiple possible library items) by either picking best match or requiring user confirmation
- [x] #7 Users can see which torrents were automatically matched in the downloads UI
- [x] #8 System avoids creating duplicate matches if the same torrent is detected multiple times
- [x] #9 Works correctly with both movie and TV show torrents
- [ ] #10 Matching confidence threshold is configurable to balance false positives vs false negatives
<!-- AC:END -->
