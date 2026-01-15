#!/bin/bash

# Function: The core logic to zip and delete a SINGLE folder
function process_folder() {
    local target_path="${1%/}" # Remove trailing slash

    # Check if folder exists
    if [ ! -d "$target_path" ]; then
        echo "Error: Directory '$target_path' does not exist."
        return 1
    fi

    local folder_name=$(basename "$target_path")
    local parent_dir=$(dirname "$target_path")

    # Create zip file in the same directory as the folder
    local zip_file="${parent_dir}/${folder_name}.zip"

    echo "Processing: $target_path"

    # Enter the folder to zip ONLY the content
    pushd "$target_path" > /dev/null

    # Create the zip file (quiet mode)
    zip -r -q "$zip_file" .
    local zip_status=$?

    # Return to original location
    popd > /dev/null

    # Delete folder ONLY if Zip was successful
    if [ $zip_status -eq 0 ]; then
        echo "  [OK] Zip created: $zip_file"
        rm -rf "$target_path"
        echo "  [OK] Original folder deleted."
    else
        echo "  [ERR] Zip creation failed for '$folder_name'. Folder NOT deleted."
        return 1
    fi
}

# Function: Extract a SINGLE archive and delete it
function extract_archive() {
    local zip_path="$1"

    # Check if file exists and is a zip file
    if [ ! -f "$zip_path" ]; then
        echo "Error: Archive '$zip_path' does not exist."
        return 1
    fi

    if [[ "$zip_path" != *.zip ]]; then
        echo "Error: '$zip_path' is not a zip file."
        return 1
    fi

    local zip_name=$(basename "$zip_path" .zip)
    local zip_dir=$(dirname "$zip_path")
    local extract_path="${zip_dir}/${zip_name}"

    echo "Extracting: $zip_path"

    # Check if target directory already exists
    if [ -d "$extract_path" ]; then
        echo "  [WARN] Directory '$extract_path' already exists. Skipping."
        return 1
    fi

    # Create target directory
    mkdir -p "$extract_path"

    # Extract the archive (quiet mode)
    unzip -q "$zip_path" -d "$extract_path"
    local extract_status=$?

    # Delete archive ONLY if extraction was successful
    if [ $extract_status -eq 0 ]; then
        echo "  [OK] Extracted to: $extract_path"
        rm -f "$zip_path"
        echo "  [OK] Archive deleted."
    else
        echo "  [ERR] Extraction failed for '$zip_name'. Archive NOT deleted."
        # Clean up the created directory if extraction failed
        rmdir "$extract_path" 2>/dev/null
        return 1
    fi
}

# Function: Recursively find album folders (folders containing MP3 files)
function find_album_folders() {
    local search_path="$1"
    local found_albums=()

    # Check if current folder contains MP3 files
    if ls "$search_path"/*.mp3 >/dev/null 2>&1; then
        found_albums+=("$search_path")
    else
        # If no MP3 files, check subfolders
        for subfolder in "$search_path"/*/; do
            [ -d "$subfolder" ] || continue
            subfolder="${subfolder%/}"

            # Recursively check subfolder
            local sub_albums
            mapfile -t sub_albums < <(find_album_folders "$subfolder")
            found_albums+=("${sub_albums[@]}")
        done
    fi

    # Output found albums
    printf '%s\n' "${found_albums[@]}"
}

# --- Main Script Logic ---

COMMAND="$1"

if [ -z "$COMMAND" ]; then
    echo "Usage:"
    echo "  music-archive <folder>     : Archive a specific folder"
    echo "  music-archive <archive.zip>: Extract a specific archive"
    echo "  music-archive list <path>  : List all unzipped folders in specified directory"
    echo "  music-archive zip <path>   : Archive all folders in specified directory"
    echo "  music-archive unzip <path> : Extract all archives in specified directory"
    exit 1
fi

# LIST MODE
if [ "$COMMAND" == "list" ]; then
    TARGET_PATH="${2%/}"  # Remove trailing slash

    # Path parameter is required
    if [ -z "$TARGET_PATH" ]; then
        echo "Error: list command requires a directory path."
        echo "Usage: music-archive list <path>"
        exit 1
    fi

    # If target path is a directory, find all album folders in it
    if [ -d "$TARGET_PATH" ]; then
        echo "Scanning for missing archives in $TARGET_PATH ..."
        count=0

        # Find all album folders recursively
        while IFS= read -r -d '' album_folder; do
            [ -n "$album_folder" ] || continue

            if [ ! -f "${album_folder}.zip" ]; then
                echo "  [MISSING] $album_folder"
                ((count++))
            fi
        done < <(find_album_folders "$TARGET_PATH" | tr '\n' '\0')

        echo "---------------------------------"
        echo "Total folders waiting to be zipped: $count"

    else
        echo "Error: '$TARGET_PATH' is not a valid directory."
        exit 1
    fi

# BATCH MODE (Accepts 'zip' OR 'archive')
elif [ "$COMMAND" == "zip" ] || [ "$COMMAND" == "archive" ]; then
    TARGET_PATH="${2%/}"  # Remove trailing slash

    # Path parameter is required
    if [ -z "$TARGET_PATH" ]; then
        echo "Error: zip command requires a directory path."
        echo "Usage: music-archive zip <path>"
        exit 1
    fi

    # If target path is a directory, archive all album folders in it
    if [ -d "$TARGET_PATH" ]; then
        echo "Starting batch archive process in: $TARGET_PATH"
        count=0

        # Find all album folders recursively
        while IFS= read -r -d '' album_folder; do
            [ -n "$album_folder" ] || continue

            # Only process if zip does not exist
            if [ ! -f "${album_folder}.zip" ]; then
                process_folder "$album_folder"
                ((count++))
            fi
        done < <(find_album_folders "$TARGET_PATH" | tr '\n' '\0')

        if [ $count -eq 0 ]; then
            echo "No unzipped album folders found in '$TARGET_PATH'."
        else
            echo "---------------------------------"
            echo "Batch archive complete. Processed $count folders."
        fi

    else
        echo "Error: '$TARGET_PATH' is not a valid directory."
        exit 1
    fi

# UNZIP MODE
elif [ "$COMMAND" == "unzip" ]; then
    TARGET_PATH="${2%/}"  # Remove trailing slash

    # Path parameter is required
    if [ -z "$TARGET_PATH" ]; then
        echo "Error: unzip command requires a path."
        echo "Usage: music-archive unzip <path>"
        exit 1
    fi

    # If target path is a specific zip file
    if [ -f "$TARGET_PATH" ] && [[ "$TARGET_PATH" == *.zip ]]; then
        extract_archive "$TARGET_PATH"

    # If target path is a directory, extract all zip files in it
    elif [ -d "$TARGET_PATH" ]; then
        echo "Starting batch extraction process in: $TARGET_PATH"
        count=0
        for zip_file in "$TARGET_PATH"/*.zip; do
            [ -f "$zip_file" ] || continue

            extract_archive "$zip_file"
            if [ $? -eq 0 ]; then
                ((count++))
            fi
        done

        if [ $count -eq 0 ]; then
            echo "No zip files found in '$TARGET_PATH'."
        else
            echo "---------------------------------"
            echo "Batch extraction complete. Processed $count archives."
        fi

    else
        echo "Error: '$TARGET_PATH' is not a valid directory or zip file."
        exit 1
    fi

# SINGLE FOLDER MODE
elif [ -d "$COMMAND" ]; then
    process_folder "$COMMAND"

# SINGLE ARCHIVE MODE
elif [ -f "$COMMAND" ] && [[ "$COMMAND" == *.zip ]]; then
    extract_archive "$COMMAND"

else
    echo "Error: '$COMMAND' is not a valid command, directory, or zip file."
    exit 1
fi
