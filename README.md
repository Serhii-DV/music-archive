# Music Archive

A bash script that efficiently manages your music collection by archiving folders into ZIP files and extracting archives back to folders.

## Overview

`music_archive.sh` is designed to help organize large music collections by:

- Converting music folders to ZIP archives
- Extracting ZIP archives back to folders
- Automatically removing original files after successful operations
- Batch processing multiple folders or archives at once
- Listing folders that haven't been archived yet

## Features

- **Single folder archiving**: Archive a specific music folder
- **Single archive extraction**: Extract a specific ZIP file to a folder
- **Batch archiving**: Archive all unzipped folders in subdirectories
- **Batch extraction**: Extract all ZIP files in a directory
- **Safety checks**: Only deletes originals after successful operations
- **Progress tracking**: Lists folders awaiting archival
- **Quiet operation**: Minimal output during operations

## Installation

1. Make the script executable:

   ```bash
   chmod +x music_archive.sh
   ```

2. (Optional) Create a symlink for easier access:

   ```bash
   ln -s $(pwd)/music_archive.sh /usr/local/bin/music-archive
   ```

3. (Optional) Create a bash alias in your `.bash_aliases` file:

   ```bash
   echo "alias music-archive='$(pwd)/music_archive.sh'" >> ~/.bash_aliases
   source ~/.bash_aliases
   ```

## Usage

### Basic Syntax

```bash
./music_archive.sh <command>
```

### Commands

#### 1. Archive a Specific Folder

```bash
./music_archive.sh <folder_path>
```

Archives a single folder and deletes the original after successful compression.

**Example:**

```bash
./music_archive.sh "Artist/Album"
```

#### 2. Extract a Specific Archive

```bash
./music_archive.sh <archive.zip>
```

Extracts a single ZIP file to a folder and deletes the archive after successful extraction.

**Example:**

```bash
./music_archive.sh "Artist - Album.zip"
```

#### 3. List Unarchived Folders

```bash
./music_archive.sh list
```

Scans for folders in `*/*/` pattern that don't have corresponding ZIP files.

**Example output:**

```txt
Scanning for missing archives in */*/ ...
  [MISSING] Artist1/Album1
  [MISSING] Artist2/Album2
---------------------------------
Total folders waiting to be zipped: 2
```

#### 3. Batch Archive All Folders

```bash
./music_archive.sh zip
# OR
./music_archive.sh archive
```

Archives all folders in `*/*/` pattern that don't already have ZIP files.

**Example output:**

```txt
Starting batch archive process...
Processing: Artist1/Album1
  [OK] Zip created: Artist1/Album1.zip
  [OK] Original folder deleted.
Processing: Artist2/Album2
  [OK] Zip created: Artist2/Album2.zip
  [OK] Original folder deleted.
---------------------------------
Batch complete. Processed 2 folders.
```

#### 5. Extract All Archives (Current Directory)

```bash
./music_archive.sh unzip
```

Extracts all ZIP files in the current directory and deletes the archives after successful extraction.

#### 6. Extract All Archives (Specific Directory)

```bash
./music_archive.sh unzip <directory_path>
```

Extracts all ZIP files in the specified directory and deletes the archives after successful extraction.

**Example:**

```bash
./music_archive.sh unzip "/mnt/d/storage/artist"
```

#### 7. Extract Specific Archive with Path

```bash
./music_archive.sh unzip <archive_path>
```

Extracts a specific ZIP file and deletes the archive after successful extraction.

**Example:**

```bash
./music_archive.sh unzip "/mnt/d/storage/artist/album.zip"
```

## Directory Structure

The script expects a music collection organized in this format:

```txt
music-collection/
├── Artist1/
│   ├── Album1/          # Will be archived to Album1.zip
│   ├── Album2/          # Will be archived to Album2.zip
│   └── Album3.zip       # Already archived (will be skipped)
├── Artist2/
│   └── Album4/          # Will be archived to Album4.zip
└── Artist3/
    └── Album5.zip       # Already archived (will be skipped)
```

## How It Works

1. **Safety First**: The script checks if the target folder exists before processing
2. **Content Preservation**: Creates ZIP files containing only the folder contents (not the folder itself)
3. **Verification**: Only deletes the original folder after confirming successful ZIP creation
4. **Error Handling**: Provides clear error messages and preserves data if compression fails

## Requirements

- **bash**: Standard bash shell
- **zip**: ZIP compression utility (usually pre-installed on most systems)
- **File permissions**: Write access to the directory containing music folders

## Examples

### Organize a new music collection

```bash
# First, see what needs archiving
./music_archive.sh list

# Archive everything at once
./music_archive.sh zip
```

### Archive a single new album

```bash
# Just downloaded "Pink Floyd/Dark Side of the Moon"
./music_archive.sh "Pink Floyd/Dark Side of the Moon"
```

### Extract archived music

```bash
# Extract all archives in current directory
./music_archive.sh unzip

# Extract all archives in a specific folder
./music_archive.sh unzip "/path/to/music/folder"

# Extract a specific album
./music_archive.sh unzip "Pink Floyd - Dark Side of the Moon.zip"
```

### Check progress

```bash
# See what's left to archive
./music_archive.sh list
```

## Error Handling

The script includes several safety features:

- Validates directory and file existence before processing
- Checks operation success before deleting originals
- Prevents overwriting existing directories during extraction
- Provides clear error messages for troubleshooting
- Preserves original files if operations fail
- Cleans up partially created directories on extraction failure

## Notes

- ZIP files are created in the same directory as the original folder
- Extracted folders are created in the same directory as the ZIP file
- Original files are permanently deleted after successful operations
- The script uses quiet mode for operations to reduce output clutter
- File and folder names with spaces are properly handled
- Existing directories will not be overwritten during extraction
