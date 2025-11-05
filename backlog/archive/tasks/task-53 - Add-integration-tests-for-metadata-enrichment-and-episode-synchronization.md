---
id: task-53
title: Add integration tests for metadata enrichment and episode synchronization
status: To Do
assignee: []
created_date: '2025-11-04 23:47'
labels:
  - testing
  - metadata
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Write integration tests for metadata enrichment and bulk episode creation using real PostgreSQL containers. This feature handles batch episode creation for TV shows (hundreds of episodes), unique constraints on (media_item_id, season_number, episode_number), UPSERT patterns for re-importing shows, and season monitoring bulk updates that require real database constraint enforcement.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Test bulk episode creation for multi-season TV shows (100+ episodes)
- [ ] #2 Test unique constraint enforcement prevents duplicate episodes on re-import
- [ ] #3 Test UPSERT behavior when importing show with existing episodes
- [ ] #4 Test season monitoring bulk updates with transaction handling
- [ ] #5 Test metadata enrichment doesn't violate foreign key constraints
- [ ] #6 All integration tests passing with real PostgreSQL container
<!-- AC:END -->
