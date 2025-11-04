---
id: task-16.2
title: Integrate batch download functionality
status: In Progress
assignee:
  - '@assistant'
created_date: '2025-11-04 21:46'
updated_date: '2025-11-04 21:55'
labels:
  - downloads
  - batch-operations
dependencies: []
parent_task_id: '16'
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Connect the batch download action to the Downloads context to actually trigger downloads for selected media items.

**Current Status:**
- Batch download button exists in toolbar
- Handler shows placeholder message

**Requirements:**
- Investigate Downloads context API for triggering downloads
- Determine how to handle movies vs TV shows (episodes)
- Implement batch download handler that:
  - Fetches download client configuration
  - Searches for media files for each selected item
  - Queues downloads for found releases
  - Shows appropriate feedback (async operation)
- Handle edge cases:
  - No download clients configured
  - No releases found for items
  - Download client errors

**Files to investigate:**
- `lib/mydia/downloads.ex` - Downloads context API
- `lib/mydia/downloads/download.ex` - Download schema
- Existing download triggering code in other LiveViews

**Files to modify:**
- `lib/mydia_web/live/media_live/index.ex` - Implement batch_download handler
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Download action triggers actual downloads for selected items
- [ ] #2 Handles movies and TV shows appropriately
- [ ] #3 Shows feedback for async download operations
- [ ] #4 Handles no download clients gracefully
- [ ] #5 Handles no releases found gracefully
- [ ] #6 Shows count of downloads queued
<!-- AC:END -->
