---
id: task-167.1
title: 'Phase 1: Replace static lists with flexible regex patterns'
status: Done
assignee: []
created_date: '2025-11-11 16:45'
updated_date: '2025-11-11 18:18'
labels:
  - enhancement
  - file-parsing
dependencies: []
parent_task_id: task-167
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Replace hardcoded lists (@audio_codecs, @codecs, @sources, etc.) with flexible regex patterns that handle variations automatically.

## Tasks

1. Create regex patterns for:
   - Audio codecs: `(?:DD(?:P)?(?:\d+\.?\d*)?|DTS(?:-HD\.MA|-HD|-X)?|TrueHD|Atmos|AAC|AC3|EAC3)`
   - Video codecs: `(?:[hx]\.?26[45]|HEVC|AVC|XviD|DivX|VP9|AV1|NVENC)`
   - Resolutions: `(?:\d{3,4}p|4K|8K|UHD)`
   - Sources: `(?:REMUX|BluRay|BDRip|BRRip|WEB(?:-DL)?|WEBRip|HDTV|DVDRip)`

2. Update extraction functions to use regex instead of list matching
3. Test with existing test suite (should pass 54/54 tests)
4. Add new test cases for codec variations

## Expected Outcome

- Handles DD5.1, DD51, DDP5.1, DDP51 with single pattern
- No more manual list updates for codec variations
- All existing tests pass

## Effort: 2-4 hours
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 All 54+ existing FileParser tests pass
- [x] #2 New test cases added for codec variations (DD51, DDP51, EAC3, etc.)
- [x] #3 Audio/video codec extraction uses regex patterns instead of static lists
- [x] #4 Code is backward compatible with existing behavior
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Phase 1 Implementation Complete

### Changes Made

**Regex Patterns Implemented:**
- **Audio codecs**: Handles DD, DDP, DD5.1, DDP5.1, DD51, DDP51, EAC3, DTS variants, TrueHD, Atmos, AAC, AC3
- **Video codecs**: Handles x264, x.264, x 264, h264, h.264, h 264, x265, h265, HEVC, AVC, XviD, DivX, VP9, AV1, NVENC
- **Resolutions**: Handles 1080p, 1080P (normalized to 1080p), 4K, 8K, UHD
- **Sources**: Handles REMUX, BluRay, BDRip, BRRip, WEB, WEB-DL, WEBRip, HDTV, DVD, DVDRip
- **HDR Formats**: Handles HDR10+, HDR10, DolbyVision, DoVi, HDR

**Normalization Logic:**
- Dots in filenames normalized to spaces (e.g., "x.264" → "x 264")
- Channel specifications restored (e.g., "5 1" → "5.1")
- Codec dots restored (e.g., "x 264" → "x.264")
- Resolution case normalized (e.g., "1080P" → "1080p")
- HDR10+ properly detected regardless of + being literal or space
- DTS-HD MA normalized to DTS-HD.MA

**Test Results:**
- ✅ All 69 tests passing
- ✅ 16 new comprehensive test cases added for codec variations
- ✅ Backward compatible with existing behavior

**Files Modified:**
- `lib/mydia/library/file_parser.ex`: Replaced static lists with regex patterns, added normalization functions
- `test/mydia/library/file_parser_test.exs`: Added comprehensive test cases for codec variations

**Benefits Achieved:**
- ✅ Robust: Single pattern handles multiple variations automatically
- ✅ Maintainable: No more manual list updates for codec variants
- ✅ Scalable: Gracefully handles edge cases
- ✅ Test Coverage: Comprehensive test suite ensures reliability
<!-- SECTION:NOTES:END -->
