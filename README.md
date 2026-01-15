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
- **Smart album detection**: Automatically finds folders containing MP3 files (actual albums)
- **Recursive scanning**: Works with any folder structure depth
- **Batch archiving**: Archive all unzipped album folders in subdirectories
- **Batch extraction**: Extract all ZIP files in a directory
- **Safety checks**: Only deletes originals after successful operations
- **Progress tracking**: Lists album folders awaiting archival
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
./music_archive.sh list <directory_path>
```

Scans for album folders (containing MP3 files) in the specified directory that don't have corresponding ZIP files. The script recursively searches through subdirectories to find actual album folders.

**Examples:**

```bash
# List unarchived albums in current directory
./music_archive.sh list .

# List unarchived albums in specific artist directory
./music_archive.sh list "Pink Floyd/"

# List unarchived albums in entire music collection
./music_archive.sh list "/mnt/d/Music/"
```

**Example output:**

```txt
Scanning for missing archives in Pink Floyd/ ...
  [MISSING] Pink Floyd/Dark Side of the Moon
  [MISSING] Pink Floyd/The Wall
---------------------------------
Total folders waiting to be zipped: 2
```

#### 4. Batch Archive All Folders

```bash
./music_archive.sh zip <directory_path>
# OR
./music_archive.sh archive <directory_path>
```

Archives all album folders (containing MP3 files) in the specified directory that don't already have ZIP files. The script recursively searches for folders containing MP3 files and treats those as album folders.

**Examples:**

```bash
# Archive all album folders in current directory
./music_archive.sh zip .

# Archive all albums in specific artist folder
./music_archive.sh zip "Pink Floyd/"

# Archive all albums in music collection
./music_archive.sh zip "/mnt/d/Music/"
```

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

#### 5. Extract All Archives

```bash
./music_archive.sh unzip <directory_or_file_path>
```

Extracts ZIP files and deletes the archives after successful extraction.

- **Directory path**: Extracts all ZIP files in the specified directory
- **File path**: Extracts a specific ZIP file

**Examples:**

```bash
# Extract all archives in current directory
./music_archive.sh unzip .

# Extract all archives in specific directory
./music_archive.sh unzip "/mnt/d/storage/artist"

# Extract specific archive
./music_archive.sh unzip "/mnt/d/storage/artist/album.zip"
```

## Directory Structure

The script works with any music collection structure and intelligently detects album folders by looking for MP3 files. It supports various organizational patterns:

### Simple Structure

```txt
music-collection/
├── Artist1/
│   ├── Album1/ (contains *.mp3) # Will be archived to Album1.zip
│   ├── Album2/ (contains *.mp3) # Will be archived to Album2.zip
│   └── Album3.zip              # Already archived (will be skipped)
├── Artist2/
│   └── Album4/ (contains *.mp3) # Will be archived to Album4.zip
└── Artist3/
    └── Album5.zip              # Already archived (will be skipped)
```

### Complex Structure

```txt
music-collection/
├── Pink Floyd/
│   ├── Studio Albums/
│   │   ├── Dark Side of the Moon/ (*.mp3) # Detected as album
│   │   └── The Wall/ (*.mp3)              # Detected as album
│   ├── Live Albums/
│   │   └── Live at Pompeii/ (*.mp3)       # Detected as album
│   └── Compilations/
│       └── Greatest Hits/ (*.mp3)         # Detected as album
└── Beatles/
    ├── Abbey Road/ (*.mp3)                # Detected as album
    └── Sgt Peppers/ (*.mp3)               # Detected as album
```

**Key Points:**

- Only folders containing MP3 files are considered "albums"
- Artist folders without MP3 files are ignored
- The script recursively searches through any folder structure
- Works with any organizational pattern or depth

## How It Works

1. **Smart Detection**: The script intelligently identifies album folders by scanning for MP3 files
2. **Recursive Search**: Works through any folder structure depth to find actual music albums
3. **Safety First**: Checks if target folders exist before processing
4. **Content Preservation**: Creates ZIP files containing only the folder contents (not the folder itself)
5. **Verification**: Only deletes original folders after confirming successful ZIP creation
6. **Error Handling**: Provides clear error messages and preserves data if operations fail

## Requirements

- **bash**: Standard bash shell
- **zip**: ZIP compression utility (usually pre-installed on most systems)
- **File permissions**: Write access to the directory containing music folders

## Examples

### Organize a new music collection

```bash
# First, see what needs archiving in current directory
./music_archive.sh list .

# Archive everything in current directory
./music_archive.sh zip .
```

### Archive a single new album

```bash
# Just downloaded "Pink Floyd/Dark Side of the Moon"
./music_archive.sh "Pink Floyd/Dark Side of the Moon"
```

### Archive all albums for specific artist

```bash
# Archive all Pink Floyd albums
./music_archive.sh zip "Pink Floyd/"

# List what needs archiving for specific artist
./music_archive.sh list "Pink Floyd/"
```

### Extract archived music

```bash
# Extract all archives in current directory
./music_archive.sh unzip .

# Extract all archives in a specific folder
./music_archive.sh unzip "/path/to/music/folder"

# Extract a specific album
./music_archive.sh unzip "Pink Floyd - Dark Side of the Moon.zip"
```

### Check progress

```bash
# See what's left to archive in current directory
./music_archive.sh list .

# See what's left to archive for specific artist
./music_archive.sh list "Pink Floyd/"
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

- Only folders containing MP3 files are considered "albums" for archiving
- The script recursively searches through folder structures of any depth
- ZIP files are created in the same directory as the original folder
- Extracted folders are created in the same directory as the ZIP file
- Original files are permanently deleted after successful operations
- The script uses quiet mode for operations to reduce output clutter
- File and folder names with spaces are properly handled
- Existing directories will not be overwritten during extraction
