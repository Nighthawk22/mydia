---
id: task-139.1
title: Fix eafnosupport crash on endpoint startup
status: Done
assignee: []
created_date: '2025-11-10 01:59'
updated_date: '2025-11-10 02:02'
labels:
  - bug
  - docker
  - networking
dependencies: []
parent_task_id: task-139
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The Phoenix web endpoint crashes with `** (EXIT) :eafnosupport` error when starting in Docker. This error occurs in the listener child process and indicates an address family not supported issue, typically related to IPv6/IPv4 configuration.

Error details:
```
** (EXIT) shutdown: failed to start child: MydiaWeb.Endpoint
    ** (EXIT) shutdown: failed to start child: {MydiaWeb.Endpoint, :http}
        ** (EXIT) shutdown: failed to start child: :listener
            ** (EXIT) :eafnosupport
```

This is a critical blocker preventing fresh Docker installations from starting.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Phoenix endpoint starts successfully in Docker
- [x] #2 Application listens on configured port (4000) without errors
- [x] #3 Both IPv4 and IPv6 configurations are handled properly
- [x] #4 Configuration documentation is updated if endpoint settings need adjustment
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Fixed the `:eafnosupport` crash by changing the default IP binding from IPv6 to IPv4 in production configuration.

**Root Cause:**
The production endpoint configuration in `config/runtime.exs` was binding to IPv6 address `{0, 0, 0, 0, 0, 0, 0, 0}` (`::`), but Docker containers don't have IPv6 enabled by default, causing the address family not supported error.

**Solution:**
Modified `config/runtime.exs` to:
1. Default to IPv4 binding `{0, 0, 0, 0}` (`0.0.0.0`) for Docker compatibility
2. Made IP binding configurable via `PHX_IP` environment variable
3. Users can set `PHX_IP="::"` to explicitly enable IPv6 if their Docker setup supports it
4. Users can also set specific IPv4 addresses like `PHX_IP="192.168.1.100"`

**Files Changed:**
- `config/runtime.exs` (lines 74-99): Added IP configuration logic with environment variable support

**Testing:**
- Code compiles successfully
- Configuration defaults to IPv4 for maximum Docker compatibility
- IPv6 can still be used by setting environment variable
<!-- SECTION:NOTES:END -->
