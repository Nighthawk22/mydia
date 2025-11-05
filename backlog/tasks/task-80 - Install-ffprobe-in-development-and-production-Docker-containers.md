---
id: task-80
title: Install ffprobe in development and production Docker containers
status: To Do
assignee: []
created_date: '2025-11-05 18:35'
labels: []
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add ffprobe installation to both the development and production Dockerfiles to enable media file metadata extraction and analysis capabilities. ffprobe is part of the FFmpeg suite and is required for analyzing video/audio files in the media library.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 ffprobe is installed in the development Docker container (Dockerfile.dev or similar)
- [ ] #2 ffprobe is installed in the production Docker container (Dockerfile or similar)
- [ ] #3 ffprobe is accessible from the application runtime environment
- [ ] #4 The installation uses minimal image size impact (e.g., ffmpeg-free or ffprobe-only package if available)
<!-- AC:END -->
