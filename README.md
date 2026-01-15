# Music Archive

A bash script that efficiently archives music folders into ZIP files and manages your music collection by converting directories to compressed archives.

## Overview

`music_archive.sh` is designed to help organize large music collections by:

- Converting music folders to ZIP archives
- Automatically removing original folders after successful compression
- Batch processing multiple folders at once
- Listing folders that haven't been archived yet

## Features

- **Single folder archiving**: Archive a specific music folder
- **Batch processing**: Archive all unzipped folders in subdirectories
- **Safety checks**: Only deletes original folders after successful ZIP creation
- **Progress tracking**: Lists folders awaiting archival
- **Quiet operation**: Minimal output during ZIP creation

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

#### 2. List Unarchived Folders

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

### Check progress

```bash
# See what's left to archive
./music_archive.sh list
```

## Error Handling

The script includes several safety features:

- Validates directory existence before processing
- Checks ZIP creation success before deleting originals
- Provides clear error messages for troubleshooting
- Preserves original folders if compression fails

## Notes

- ZIP files are created in the same directory as the original folder
- Original folders are permanently deleted after successful archiving
- The script uses quiet mode for ZIP creation to reduce output clutter
- Folder names with spaces are properly handled
