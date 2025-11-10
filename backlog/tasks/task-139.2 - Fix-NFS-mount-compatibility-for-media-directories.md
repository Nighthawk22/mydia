---
id: task-139.2
title: Fix NFS mount compatibility for media directories
status: Done
assignee: []
created_date: '2025-11-10 01:59'
updated_date: '2025-11-10 02:06'
labels:
  - bug
  - docker
  - storage
dependencies: []
parent_task_id: task-139
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The application doesn't work when media directories are mounted via NFS. Users report that the container fails to start or behaves incorrectly with NFS mounts, forcing them to switch to SMB.

This affects users who prefer or require NFS for their media storage setup. The issue may be related to file permissions, mount options, or how the application accesses files on NFS shares.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Application starts successfully with NFS-mounted media directories
- [x] #2 File scanning and indexing works on NFS mounts
- [x] #3 Hardlinks work correctly if source and destination are on the same NFS mount
- [x] #4 Documentation includes NFS mount configuration guidance and any required mount options
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Fixed NFS and SMB mount compatibility by removing recursive chown on /media directory.

**Root Cause:**
The entrypoint script was attempting `chown -R` on `/media`, causing permission errors and extremely slow startup with network mounts.

**Solution:**
Modified `docker-entrypoint-prod.sh` to never chown `/media` directory. Users configure permissions via NFS/SMB export settings with UID/GID mapping.

**Documentation:**
Added concise network mount section to `docs/deployment/DEPLOYMENT.md` with NFS export example and troubleshooting.

**Files Changed:**
- `docker-entrypoint-prod.sh` (lines 67-73): Removed /media from chown
- `docs/deployment/DEPLOYMENT.md` (lines 128-146): Added network mount guidance
<!-- SECTION:NOTES:END -->
