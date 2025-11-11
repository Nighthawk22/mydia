---
id: task-167.5
title: >-
  Add test case for "Black Phone 2. 2025 1080P WEB-DL DDP5.1 Atmos. X265.
  POOLTED.mkv" and fix parsing
status: In Progress
assignee:
  - '@Claude'
created_date: '2025-11-11 19:52'
updated_date: '2025-11-11 19:53'
labels:
  - testing
  - file-parsing
  - bug-fix
dependencies: []
parent_task_id: '167'
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## Problem

Real-world filename that may not be parsing correctly:
```
Black Phone 2. 2025 1080P WEB-DL DDP5.1 Atmos. X265. POOLTED.mkv
```

Full path:
```
/media/movies/Black Phone 2 (2025)/Black Phone 2. 2025 1080P WEB-DL DDP5.1 Atmos. X265. POOLTED.mkv
```

File size: 3.1 GB

## Expected Parsing

- **Title**: "Black Phone 2"
- **Year**: 2025
- **Type**: movie
- **Resolution**: 1080p (normalized from 1080P)
- **Source**: WEB-DL
- **Audio**: DDP5.1 or Atmos (or both)
- **Codec**: x265 or X265
- **Release Group**: POOLTED

## Tasks

1. Add test case to `test/mydia/library/file_parser_v2_test.exs`
2. Run test to verify current parsing behavior
3. Fix any issues with:
   - Title extraction (ensure "Black Phone 2" is extracted correctly)
   - Year extraction (2025)
   - Case normalization (1080P -> 1080p, X265 -> x265)
   - Audio codec handling (DDP5.1 Atmos)
4. Verify all existing tests still pass

## Notes

This is a real-world example that should work with FileParser V2's sequential extraction approach. The test will serve as regression prevention.
<!-- SECTION:DESCRIPTION:END -->
