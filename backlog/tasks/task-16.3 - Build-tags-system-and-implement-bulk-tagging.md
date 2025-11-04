---
id: task-16.3
title: Build tags system and implement bulk tagging
status: To Do
assignee: []
created_date: '2025-11-04 21:46'
labels:
  - tags
  - batch-operations
  - schema
dependencies: []
parent_task_id: '16'
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create tags functionality for media items and implement bulk tag assignment/removal in batch operations.

**Prerequisites:**
- Design tags schema and database tables
- Implement tags context with CRUD operations
- Add tags association to MediaItem schema

**Tag System Design:**
1. **Tags Schema**
   - id, name, color (optional)
   - Many-to-many relationship with MediaItems
   - Unique constraint on tag name

2. **Tags Context**
   - `list_tags/0` - Get all tags
   - `create_tag(attrs)` - Create new tag
   - `delete_tag(tag)` - Delete tag
   - `assign_tags_to_media(media_id, tag_ids)` - Assign tags
   - `remove_tags_from_media(media_id, tag_ids)` - Remove tags
   - `batch_assign_tags(media_ids, tag_ids)` - Bulk assign
   - `batch_remove_tags(media_ids, tag_ids)` - Bulk remove

3. **Batch Tagging UI**
   - Add tags section to batch edit modal
   - Multi-select for adding tags
   - Multi-select for removing tags
   - Show current tags (if any common tags across selection)
   - Create new tags inline

**Files to create:**
- Migration for tags and media_tags join table
- `lib/mydia/tags/tag.ex` - Tag schema
- `lib/mydia/tags.ex` - Tags context

**Files to modify:**
- `lib/mydia/media/media_item.ex` - Add tags association
- `lib/mydia_web/live/media_live/index.ex` - Load tags, handle tag actions
- `lib/mydia_web/live/media_live/index.html.heex` - Add tags section to batch edit modal
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Tags schema and migration created
- [ ] #2 Tags context with CRUD operations
- [ ] #3 MediaItem has tags association
- [ ] #4 Can assign tags to media items
- [ ] #5 Can remove tags from media items
- [ ] #6 Batch edit modal includes tag assignment
- [ ] #7 Batch edit modal includes tag removal
- [ ] #8 Can create new tags inline during batch edit
- [ ] #9 Batch tag operations are transactional
<!-- AC:END -->
