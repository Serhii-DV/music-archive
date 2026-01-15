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

    # Absolute path for the new zip file
    local zip_file="${PWD}/${parent_dir}/${folder_name}.zip"

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

# --- Main Script Logic ---

COMMAND="$1"

if [ -z "$COMMAND" ]; then
    echo "Usage:"
    echo "  music-archive <folder>     : Archive a specific folder"
    echo "  music-archive <archive.zip>: Extract a specific archive"
    echo "  music-archive list         : List all unzipped folders in */*/"
    echo "  music-archive zip          : Archive all unzipped folders in */*/"
    echo "  music-archive unzip        : Extract all archives in current directory"
    echo "  music-archive unzip <path> : Extract all archives in specified directory"
    echo "  music-archive unzip <file> : Extract specific archive file"
    exit 1
fi

# LIST MODE
if [ "$COMMAND" == "list" ]; then
    echo "Scanning for missing archives in */*/ ..."
    count=0
    for dir in */*/; do
        [ -d "$dir" ] || continue
        clean_dir="${dir%/}"

        if [ ! -f "${clean_dir}.zip" ]; then
            echo "  [MISSING] $clean_dir"
            ((count++))
        fi
    done
    echo "---------------------------------"
    echo "Total folders waiting to be zipped: $count"

# BATCH MODE (Accepts 'zip' OR 'archive')
elif [ "$COMMAND" == "zip" ] || [ "$COMMAND" == "archive" ]; then
    echo "Starting batch archive process..."
    count=0
    for dir in */*/; do
        [ -d "$dir" ] || continue
        clean_dir="${dir%/}"

        # Only process if zip does not exist
        if [ ! -f "${clean_dir}.zip" ]; then
            process_folder "$clean_dir"
            ((count++))
        fi
    done

    if [ $count -eq 0 ]; then
        echo "No unzipped folders found."
    else
        echo "---------------------------------"
        echo "Batch complete. Processed $count folders."
    fi

# UNZIP MODE
elif [ "$COMMAND" == "unzip" ]; then
    TARGET_PATH="$2"

    # If no target path specified, use current directory
    if [ -z "$TARGET_PATH" ]; then
        echo "Starting batch extraction process in current directory..."
        count=0
        for zip_file in *.zip; do
            [ -f "$zip_file" ] || continue

            extract_archive "$zip_file"
            if [ $? -eq 0 ]; then
                ((count++))
            fi
        done

        if [ $count -eq 0 ]; then
            echo "No zip files found or processed."
        else
            echo "---------------------------------"
            echo "Batch extraction complete. Processed $count archives."
        fi

    # If target path is a specific zip file
    elif [ -f "$TARGET_PATH" ] && [[ "$TARGET_PATH" == *.zip ]]; then
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
