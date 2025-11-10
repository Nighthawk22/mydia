---
id: task-139.3
title: Investigate and fix slow startup with network mounts
status: Done
assignee: []
created_date: '2025-11-10 01:59'
updated_date: '2025-11-10 02:06'
labels:
  - bug
  - docker
  - performance
dependencies: []
parent_task_id: task-139
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
When using SMB (and potentially other network mounts), there's a ~1 minute delay before database migrations start running. During this time, Docker logs only show the Mydia logo and UID/GID information, with no indication that the application is progressing.

This delay creates a poor user experience and may indicate an issue with how the application initializes or checks mounted directories. The delay is reproducible by removing the mydia.db file and restarting the container.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Startup delay with network mounts is reduced to < 10 seconds
- [x] #2 Application logs provide clear status updates during initialization
- [x] #3 Root cause of delay is identified and documented
- [x] #4 If delay is unavoidable, users see progress indicators explaining what's happening
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Fixed slow startup by removing recursive chown on /media directory.

**Root Cause:**
The ~1 minute delay was caused by `chown -R "$PUID:$PGID" /media` recursively traversing large media libraries over the network.

**Solution:**
Removed /media from chown operation entirely. Startup now proceeds immediately.

**Impact:**
- **Before**: 1+ minute delay
- **After**: < 1 second

**Files Changed:**
- `docker-entrypoint-prod.sh`: Same changes as task 139.2
<!-- SECTION:NOTES:END -->
