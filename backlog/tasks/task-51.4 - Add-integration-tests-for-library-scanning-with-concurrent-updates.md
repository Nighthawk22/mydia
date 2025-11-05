---
id: task-51.4
title: Add integration tests for library scanning with concurrent updates
status: To Do
assignee: []
created_date: '2025-11-04 23:49'
labels:
  - testing
  - library
dependencies: []
parent_task_id: task-51
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Write integration tests for library scanning using real PostgreSQL containers. The scanner processes thousands of files in transactions with change detection, concurrent scans on multiple paths, bulk update operations, and lock contention scenarios that require real database semantics to properly test rollback behavior and transaction isolation.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Test atomic transaction processing of large file batches (add/update/delete)
- [ ] #2 Test transaction rollback on partial scan failures
- [ ] #3 Test concurrent scans on overlapping library paths
- [ ] #4 Test bulk update semantics for scan status tracking
- [ ] #5 Test lock contention when multiple scans run in parallel
- [ ] #6 All integration tests passing with real PostgreSQL container
<!-- AC:END -->
