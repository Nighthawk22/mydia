---
id: task-51
title: Add Testcontainers-based integration testing for critical workflows
status: To Do
assignee: []
created_date: '2025-11-04 23:49'
labels:
  - testing
  - infrastructure
dependencies:
  - task-12
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement comprehensive integration testing using Testcontainers to validate complex database operations, transactions, concurrent updates, and constraint enforcement against real PostgreSQL containers. This covers download workflows, metadata enrichment, library scanning, and bulk operations that cannot be adequately tested with mocks.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Testcontainers infrastructure fully configured and documented
- [ ] #2 Integration tests written for download monitoring and import workflow
- [ ] #3 Integration tests written for metadata enrichment and episode sync
- [ ] #4 Integration tests written for library scanning with concurrent updates
- [ ] #5 Integration tests written for bulk media operations and cascades
- [ ] #6 All integration tests passing in CI with real PostgreSQL containers
<!-- AC:END -->
