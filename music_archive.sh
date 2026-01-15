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

# --- Main Script Logic ---

COMMAND="$1"

if [ -z "$COMMAND" ]; then
    echo "Usage:"
    echo "  music-archive <folder>   : Archive a specific folder"
    echo "  music-archive list       : List all unzipped folders in */*/"
    echo "  music-archive zip        : Archive all unzipped folders in */*/"
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

# SINGLE FOLDER MODE
elif [ -d "$COMMAND" ]; then
    process_folder "$COMMAND"

else
    echo "Error: '$COMMAND' is not a valid command or directory."
    exit 1
fi
