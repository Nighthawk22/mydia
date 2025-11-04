---
id: task-16.4
title: Add progress indicators for batch operations
status: To Do
assignee: []
created_date: '2025-11-04 21:46'
labels:
  - ui
  - ux
  - performance
dependencies: []
parent_task_id: '16'
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add visual progress feedback for batch operations, especially important for large selections (50+ items).

**Requirements:**
1. **Loading State During Operations**
   - Disable action buttons while operation in progress
   - Show spinner/loading indicator
   - Prevent multiple simultaneous operations

2. **Progress Bar for Large Batches**
   - For selections > 50 items, show progress bar
   - Update progress as items are processed
   - Consider chunked processing to avoid timeout

3. **Operation Feedback**
   - Show "Processing X of Y items..."
   - Estimated time remaining (optional)
   - Allow cancellation of long operations (optional)

**Implementation Options:**
- **Simple**: Add loading state to batch action buttons
- **Advanced**: Use LiveView async operations with progress updates
- **Very Advanced**: Use Oban jobs with progress tracking via Phoenix.PubSub

**Files to modify:**
- `lib/mydia_web/live/media_live/index.ex` - Add loading state, async operations
- `lib/mydia_web/live/media_live/index.html.heex` - Loading indicators on buttons
- `lib/mydia/media.ex` - Consider chunked batch processing for large sets

**Edge Cases:**
- Operations that complete instantly (< 100ms)
- Very large selections (500+ items)
- Concurrent batch operations
- Browser refresh during operation
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Action buttons disabled during operations
- [ ] #2 Loading spinner shown during batch operations
- [ ] #3 Progress bar for operations > 50 items
- [ ] #4 Cannot trigger multiple operations simultaneously
- [ ] #5 Clear feedback when operation completes
- [ ] #6 Handles operation failures gracefully
<!-- AC:END -->
