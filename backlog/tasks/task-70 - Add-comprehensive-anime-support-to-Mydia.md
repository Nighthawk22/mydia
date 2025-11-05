---
id: task-70
title: Add comprehensive anime support to Mydia
status: To Do
assignee: []
created_date: '2025-11-05 14:34'
updated_date: '2025-11-05 14:35'
labels:
  - enhancement
  - anime
  - metadata
  - ui
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement full-featured anime support including MyAnimeList integration, absolute episode numbering, fansub handling, and anime-specific UI enhancements.

## Context
Currently, anime content is treated as generic TV shows/movies, lacking:
- Anime-specific metadata sources (MAL, AniDB)
- Absolute episode numbering for long-running shows
- Fansub-aware file parsing and quality selection
- Anime-specific UI features and filtering

## Approach
Use a hybrid approach where anime is identified via `is_anime` flag while keeping existing tv_show/movie types. Integrate MyAnimeList as the primary anime metadata provider. Support both seasonal anime (standard S/E numbering) and long-running shows (absolute numbering).

## Technical Requirements
- Database migrations for anime fields (is_anime, mal_id, absolute_episode_number, episode_type)
- MAL provider adapter implementing Mydia.Metadata.Provider behaviour
- Extended file parser for anime naming patterns and fansub tags
- Enhanced release ranker with fansub group preferences
- UI updates across media library, search, downloads, and detail pages
- Background jobs for anime metadata refresh and episode updates
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Users can mark media items as anime with is_anime flag
- [ ] #2 MAL metadata is fetched and displayed for anime content
- [ ] #3 Absolute episode numbering works for long-running shows (One Piece, Naruto)
- [ ] #4 Anime file naming patterns are correctly parsed (e.g., [Fansub] Title - 001 [Quality].mkv)
- [ ] #5 Fansub groups are identified and can be preferred/blocked in quality profiles
- [ ] #6 Anime content is filterable in the media library UI
- [ ] #7 MAL ratings and anime-specific metadata are displayed on detail pages
- [ ] #8 Episode types (regular, OVA, special, movie) are properly categorized
- [ ] #9 Dual audio releases are detected and can be preferred
- [ ] #10 Batch releases are properly identified and handled
- [ ] #11 All existing tests pass and new features have test coverage
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Phase 1: Foundation & Schema Changes

### 1.1 Database Migration - Media Items
- Add `is_anime` boolean field (default false)
- Add `mal_id` integer field (nullable)
- Add `anilist_id` integer field (nullable)
- Extend `metadata` JSONB for anime-specific data

### 1.2 Database Migration - Episodes
- Add `absolute_episode_number` integer field (nullable)
- Add `episode_type` string field (regular, special, ova, movie, opening, ending)

### 1.3 Update Schemas
- Update `MediaItem` schema in `lib/mydia/media/media_item.ex`
- Update `Episode` schema in `lib/mydia/media/episode.ex`
- Add validations and changesets for new fields

## Phase 2: MyAnimeList Provider Integration

### 2.1 MAL Provider Adapter
- Create `lib/mydia/metadata/provider/mal.ex`
- Implement `Mydia.Metadata.Provider` behaviour
- Use Jikan API (unofficial MAL REST API) via `:req`
- Implement search/fetch_by_id/fetch_episodes functions

### 2.2 Configuration
- Add MAL settings to settings system
- Configure API endpoints and rate limiting
- Add caching layer for MAL responses

### 2.3 Multi-Provider Support
- Implement metadata merging from TMDB + MAL
- Prefer MAL for anime-specific fields
- Graceful fallbacks when providers unavailable

## Phase 3: Episode Numbering & File Parsing

### 3.1 Extend File Parser
- Add anime patterns: `[Fansub] Title - 001 [Quality].mkv`
- Parse absolute episode numbers
- Extract fansub group tags
- Detect batch releases `[01-12]`

### 3.2 Episode Matching
- Match files using absolute_episode_number
- Support episode type matching
- Handle special episodes (OVA, specials)

## Phase 4: Release Ranking & Fansub Handling

### 4.1 Release Ranker Enhancement
- Parse fansub groups from titles
- Add anime-specific scoring factors
- Detect dual audio releases
- Identify mini vs high-quality encodes

### 4.2 Quality Profile Extensions
- Add fansub group preferences (preferred/blocked lists)
- Add dual audio preference toggle
- Add batch download preference

## Phase 5: UI/UX Enhancements

### 5.1 Media Library Updates
- Add anime filter to `MediaLive.Index`
- Show anime badge/indicator
- Display MAL ratings

### 5.2 Media Detail Page
- Show anime-specific metadata (studios, JP title, MAL score)
- Display absolute episode numbers
- Show fansub group info
- Add MAL page link

### 5.3 Search & Downloads
- Indicate anime in search results
- Add anime-specific filters
- Display fansub groups in downloads
- Highlight dual audio releases

## Phase 6: Background Jobs & Automation

### 6.1 Anime Metadata Refresh Job
- Periodic MAL metadata updates
- Fetch new episodes for ongoing series
- Update absolute numbering

### 6.2 Search Job Enhancements
- Use anime indexer categories (5070)
- Apply fansub preferences
- Handle batch releases

## Phase 7: Testing

### 7.1 Unit Tests
- MAL provider adapter tests
- File parser anime pattern tests
- Release ranker fansub scoring tests

### 7.2 Integration Tests
- Multi-provider metadata fetching
- Episode matching with absolute numbers
- Fansub preference application

### 7.3 LiveView Tests
- Anime filtering UI
- Metadata display
- Search and downloads pages
<!-- SECTION:PLAN:END -->
