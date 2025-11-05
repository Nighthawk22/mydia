---
id: task-51.2
title: Add integration tests for download monitoring and import workflow
status: To Do
assignee: []
created_date: '2025-11-04 23:49'
labels:
  - testing
  - downloads
dependencies: []
parent_task_id: task-51
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Write integration tests for the download monitoring and media import pipeline using real PostgreSQL containers. This workflow has complex state transitions (pending → downloading → completed → failed), concurrent updates, foreign key relationships, transaction atomicity, and cascade delete behavior that require real database testing to properly validate.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Test download state transitions with concurrent updates from multiple jobs
- [ ] #2 Test media import creates media_file records atomically with download status updates
- [ ] #3 Test race conditions between download monitor updates and import job execution
- [ ] #4 Test cascade delete behavior when media items with downloads are deleted
- [ ] #5 Test transaction rollback when import fails mid-operation
- [ ] #6 All integration tests passing with real PostgreSQL container
<!-- AC:END -->
