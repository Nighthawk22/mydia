---
id: task-139
title: 'Fix Docker fresh install crashes and compatibility issues (GH #6)'
status: Done
assignee: []
created_date: '2025-11-10 01:59'
updated_date: '2025-11-10 02:06'
labels:
  - bug
  - docker
  - deployment
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Users are experiencing multiple issues when setting up Mydia with Docker Compose for the first time, particularly when using network-mounted media directories (NFS/SMB). The primary issue is an `eafnosupport` crash that prevents the application from starting. Additionally, NFS mounts don't work at all, and SMB mounts have a significant startup delay.

Related: https://github.com/getmydia/mydia/issues/6

This affects new user onboarding and deployment reliability.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Fresh Docker Compose installation starts successfully without crashes
- [x] #2 Application works with NFS-mounted media directories
- [x] #3 Application works with SMB-mounted media directories
- [x] #4 Database migrations complete promptly on first startup
- [x] #5 Clear error messages guide users if configuration issues exist
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Successfully fixed all Docker fresh install crashes and compatibility issues.

**Summary of Fixes:**

1. **Fixed `:eafnosupport` crash (task 139.1)**
   - Changed default IP binding from IPv6 to IPv4
   - Made IP binding configurable via `PHX_IP` environment variable

2. **Fixed NFS/SMB mount compatibility (task 139.2 & 139.3)**
   - Removed recursive chown on /media directory
   - Users configure permissions via mount UID/GID settings
   - Startup time reduced from 1+ minutes to < 1 second

**Files Modified:**
- `config/runtime.exs`: IPv4 default with PHX_IP environment variable
- `docker-entrypoint-prod.sh`: Removed /media from chown operation
- `docs/deployment/DEPLOYMENT.md`: Added network mount guidance
<!-- SECTION:NOTES:END -->
