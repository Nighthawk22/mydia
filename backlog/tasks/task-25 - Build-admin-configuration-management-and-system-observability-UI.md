---
id: task-25
title: Build admin configuration management and system observability UI
status: In Progress
assignee: []
created_date: '2025-11-04 03:52'
updated_date: '2025-11-04 23:43'
labels:
  - admin
  - ui
  - configuration
  - observability
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create comprehensive admin interface for monitoring system state and managing configuration. This includes a status dashboard showing current configuration, folder monitoring, download clients, and indexers, plus a configuration management system that allows UI-based changes to override file-based config (but not environment variables). The UI should clearly indicate the source of each configuration value (env var, database/UI, config.yml, or default) to provide full transparency to administrators.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Admin role can access system status and configuration features
- [ ] #2 Configuration precedence is correctly implemented: env vars > database/UI > config.yml > defaults
- [ ] #3 UI clearly shows configuration source for each setting
- [ ] #4 All configuration changes made via UI are persisted to database
- [ ] #5 Environment variables cannot be overridden by UI (read-only display)
- [ ] #6 System follows technical.md architecture and product.md vision for self-hosting simplicity
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Partial Completion Status

Core configuration system is complete via subtasks:
- ✅ task-25.1: Admin system status dashboard created
- ✅ task-25.2: Database schema for UI-managed configuration
- ✅ task-25.3: Configuration resolution system with precedence
- ✅ task-25.4: Configuration management LiveView with source transparency

**Remaining work:**
- task-25.5 (To Do): REST API endpoints for configuration management
- task-25.6 (To Do): Display real Oban statistics in admin status dashboard

Most acceptance criteria are met. The UI-based configuration management is functional. API endpoints and Oban statistics display are the main gaps.
<!-- SECTION:NOTES:END -->
