---
id: task-51.5
title: Add integration tests for bulk media operations and cascades
status: To Do
assignee: []
created_date: '2025-11-04 23:49'
labels:
  - testing
  - media
dependencies: []
parent_task_id: task-51
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Write integration tests for bulk media operations using real PostgreSQL containers. These operations use Repo.transaction() to wrap bulk updates/deletes across media items, episodes, media_files, and downloads. Real database testing is essential to verify cascading deletes, constraint enforcement, transaction atomicity, and rollback behavior with complex foreign key relationships.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Test bulk delete of media items with hundreds of associated episodes and files
- [ ] #2 Test cascading deletes properly clean up all related records
- [ ] #3 Test transaction rollback on constraint violations during bulk operations
- [ ] #4 Test bulk update atomicity - all updates succeed or all fail
- [ ] #5 Test foreign key constraint enforcement for quality_profile_id and other references
- [ ] #6 All integration tests passing with real PostgreSQL container
<!-- AC:END -->
