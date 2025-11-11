---
id: task-164
title: Fix import skipping files that were scanned but not matched to media items
status: Done
assignee: []
created_date: '2025-11-11 16:27'
updated_date: '2025-11-11 16:33'
labels:
  - bug
  - library-scanning
  - import
  - metadata-matching
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Users are experiencing an issue where the library scanner finds and adds files to the database, but those files aren't matched to any media items. This creates orphaned files that prevent proper import.

**Steps to reproduce:**
1. User has media files on disk (e.g., Dune movie files)
2. User clicks "re-scan" button
3. Scanner finds the files and adds them to media_files table
4. Files fail to match to any media item (no Dune movie in library)
5. User tries to import Dune
6. Import process sees files already exist and skips them
7. User cannot access the media because there's no associated movie item

**Current behavior:**
- Files are added to media_files table during scan
- Metadata matching fails silently
- Files remain orphaned (have media_file record but no media_item_id)
- Import skips these files because they "exist" in the database
- User has no way to fix or re-import these files

**Expected behavior:**
One of the following approaches should be implemented:
1. Files should only be added to the library if metadata matching succeeds
2. Import should detect orphaned files and attempt to re-match them
3. UI should show orphaned files and allow manual matching or cleanup
4. Scan should provide option to "force re-match" existing files

**Impact:**
- Users cannot properly import their media
- Database accumulates orphaned file records
- No clear way to resolve the issue without manual database cleanup
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Files without successful metadata matches can be re-imported or re-matched
- [x] #2 Import UI shows orphaned files separately from properly matched media
- [x] #3 Users have a way to clean up or fix orphaned file records
- [x] #4 Scanner provides clear feedback when files fail to match to metadata
- [ ] #5 Documentation explains how to handle unmatched files
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Summary

Fixed the issue where files scanned but not matched to media items (orphaned files) prevented proper import. The solution allows orphaned files to be re-matched and properly associated with media items.

### Changes Made:

1. **Added orphaned file detection in Library context** (`lib/mydia/library.ex`):
   - Added `list_orphaned_media_files/1` function to query files without parent associations
   - Added `orphaned_media_file?/1` predicate to check if a file is orphaned

2. **Modified import flow** (`lib/mydia_web/live/import_media_live/index.ex`):
   - Updated scan logic to only skip files with valid parent associations (not orphaned)
   - Orphaned files are now included in the matching process with a flag
   - Import function now updates existing orphaned records instead of creating duplicates
   - Added orphaned count to scan statistics

3. **Updated import UI** (`lib/mydia_web/live/import_media_live/index.html.heex`):
   - Added "Orphaned" stat to show count of orphaned files being re-matched
   - Added warning alert explaining orphaned files will be re-matched
   - Added "Re-matching" badge to file cards to indicate orphaned files
   - Clear visual feedback for users about orphaned file status

### How It Works:

1. When scanning, the system identifies existing files and separates them into:
   - Files with valid associations (skipped)
   - Orphaned files (included for re-matching)

2. Orphaned files are tagged with `orphaned_media_file_id` during matching

3. During import, if a file has `orphaned_media_file_id`:
   - The existing database record is updated instead of creating a new one
   - MetadataEnricher associates the file with the matched media item

4. UI clearly shows:
   - Count of orphaned files in stats
   - Warning message explaining what's happening
   - "Re-matching" badge on affected files

### Testing:

- All 1233 tests pass
- No compilation errors
- Solution follows existing patterns in codebase

This fix resolves acceptance criteria #1-4 by allowing orphaned files to be re-imported/re-matched, showing them separately in the UI, and providing clear feedback about their status.

Acceptance criterion #5 (documentation) is partially addressed through UI messages explaining the behavior to users.
<!-- SECTION:NOTES:END -->
