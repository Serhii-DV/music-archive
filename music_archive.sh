#!/bin/bash

if [ -t 1 ]; then
    COLOR_RESET=$'\033[0m'
    COLOR_RED=$'\033[0;31m'
    COLOR_GREEN=$'\033[0;32m'
    COLOR_YELLOW=$'\033[0;33m'
    COLOR_BLUE=$'\033[0;34m'
    COLOR_BOLD=$'\033[1m'
else
    COLOR_RESET=""
    COLOR_RED=""
    COLOR_GREEN=""
    COLOR_YELLOW=""
    COLOR_BLUE=""
    COLOR_BOLD=""
fi

function print_info() {
    echo -e "${COLOR_BLUE}$1${COLOR_RESET}"
}

function print_success() {
    echo -e "${COLOR_GREEN}$1${COLOR_RESET}"
}

function print_warning() {
    echo -e "${COLOR_YELLOW}$1${COLOR_RESET}"
}

function print_error() {
    echo -e "${COLOR_RED}$1${COLOR_RESET}"
}

function print_heading() {
    echo -e "${COLOR_BOLD}$1${COLOR_RESET}"
}

function print_help_line() {
    local command_text="$1"
    local description="$2"
    local padded_command

    printf -v padded_command "%-28s" "$command_text"
    echo -e "  ${COLOR_GREEN}${padded_command}${COLOR_RESET} ${COLOR_BLUE}:${COLOR_RESET} ${description}"
}

function print_usage() {
    print_heading "Usage:"
    print_help_line "music-archive <folder>" "List all unzipped folders in a directory"
    print_help_line "music-archive <archive.zip>" "Extract a specific archive"
    print_help_line "music-archive <path> list" "List all unzipped folders in a directory"
    print_help_line "music-archive <path> zip" "Archive all album folders in a directory"
    print_help_line "music-archive <path> archive" "Same as zip"
    print_help_line "music-archive <path> unzip" "Extract all archives in a directory"
    print_help_line "music-archive help" "Show this help screen"
    print_help_line "music-archive --help" "Show this help screen"
}

# Function: The core logic to zip and delete a SINGLE folder
function process_folder() {
    local target_path="${1%/}" # Remove trailing slash

    # Check if folder exists
    if [ ! -d "$target_path" ]; then
        print_error "Error: Directory '$target_path' does not exist."
        return 1
    fi

    local folder_name=$(basename "$target_path")
    local parent_dir=$(dirname "$target_path")

    # Create zip file in the same directory as the folder
    local zip_file="${parent_dir}/${folder_name}.zip"

    print_info "Processing: $target_path"

    # Enter the folder to zip ONLY the content
    pushd "$target_path" > /dev/null

    # Create the zip file (quiet mode)
    zip -r -q "$zip_file" .
    local zip_status=$?

    # Return to original location
    popd > /dev/null

    # Delete folder ONLY if Zip was successful
    if [ $zip_status -eq 0 ]; then
        print_success "  [OK] Zip created: $zip_file"
        rm -rf "$target_path"
        print_success "  [OK] Original folder deleted."
    else
        print_error "  [ERR] Zip creation failed for '$folder_name'. Folder NOT deleted."
        return 1
    fi
}

# Function: Extract a SINGLE archive and delete it
function extract_archive() {
    local zip_path="$1"

    # Check if file exists and is a zip file
    if [ ! -f "$zip_path" ]; then
        print_error "Error: Archive '$zip_path' does not exist."
        return 1
    fi

    if [[ "$zip_path" != *.zip ]]; then
        print_error "Error: '$zip_path' is not a zip file."
        return 1
    fi

    local zip_name=$(basename "$zip_path" .zip)
    local zip_dir=$(dirname "$zip_path")
    local extract_path="${zip_dir}/${zip_name}"

    print_info "Extracting: $zip_path"

    # Check if target directory already exists
    if [ -d "$extract_path" ]; then
        print_warning "  [WARN] Directory '$extract_path' already exists. Skipping."
        return 1
    fi

    # Create target directory
    mkdir -p "$extract_path"

    # Extract the archive (quiet mode)
    unzip -q "$zip_path" -d "$extract_path"
    local extract_status=$?

    # Delete archive ONLY if extraction was successful
    if [ $extract_status -eq 0 ]; then
        print_success "  [OK] Extracted to: $extract_path"
        rm -f "$zip_path"
        print_success "  [OK] Archive deleted."
    else
        print_error "  [ERR] Extraction failed for '$zip_name'. Archive NOT deleted."
        # Clean up the created directory if extraction failed
        rmdir "$extract_path" 2>/dev/null
        return 1
    fi
}

# Common audio formats that qualify a folder for archiving.
# Popular lossless formats matched here: FLAC, WAV, AIFF, APE, WavPack.
SUPPORTED_AUDIO_EXTENSIONS=(
    "mp3"
    "flac"
    "wav"
    "aiff"
    "aif"
    "ape"
    "wv"
)

function has_supported_audio_files() {
    local search_path="$1"
    local extension

    for extension in "${SUPPORTED_AUDIO_EXTENSIONS[@]}"; do
        if find "$search_path" -maxdepth 1 -type f -iname "*.${extension}" | read -r; then
            return 0
        fi
    done

    return 1
}

# Function: Recursively find album folders (folders containing supported audio files)
function find_album_folders() {
    local search_path="$1"
    local found_albums=()

    # Check if current folder contains supported audio files
    if has_supported_audio_files "$search_path"; then
        found_albums+=("$search_path")
    else
        # If no supported audio files, check subfolders
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

TARGET_PATH="${1%/}"
COMMAND="$2"

if [ -z "$TARGET_PATH" ] || [ "$TARGET_PATH" == "help" ] || [ "$TARGET_PATH" == "--help" ]; then
    print_usage
    exit 1
fi

# LIST MODE
if [ "$COMMAND" == "list" ] || { [ -z "$COMMAND" ] && [ -d "$TARGET_PATH" ]; }; then
    # Path parameter is required
    if [ -z "$TARGET_PATH" ]; then
        print_error "Error: list command requires a directory path."
        print_heading "Usage: music-archive <path> list"
        exit 1
    fi

    # If target path is a directory, find all album folders in it
    if [ -d "$TARGET_PATH" ]; then
        print_info "Scanning for missing archives in $TARGET_PATH ..."
        count=0

        # Find all album folders recursively
        while IFS= read -r -d '' album_folder; do
            [ -n "$album_folder" ] || continue

            if [ ! -f "${album_folder}.zip" ]; then
                print_warning "  [MISSING] $album_folder"
                ((count++))
            fi
        done < <(find_album_folders "$TARGET_PATH" | tr '\n' '\0')

        print_heading "---------------------------------"
        print_heading "Total folders waiting to be zipped: $count"

    else
        print_error "Error: '$TARGET_PATH' is not a valid directory."
        exit 1
    fi

# BATCH MODE (Accepts 'zip' OR 'archive')
elif [ "$COMMAND" == "zip" ] || [ "$COMMAND" == "archive" ]; then
    # Path parameter is required
    if [ -z "$TARGET_PATH" ]; then
        print_error "Error: zip command requires a directory path."
        print_heading "Usage: music-archive <path> zip"
        exit 1
    fi

    # If target path is a directory, archive all album folders in it
    if [ -d "$TARGET_PATH" ]; then
        print_info "Starting batch archive process in: $TARGET_PATH"
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
            print_warning "No unzipped album folders found in '$TARGET_PATH'."
        else
            print_heading "---------------------------------"
            print_success "Batch archive complete. Processed $count folders."
        fi

    else
        print_error "Error: '$TARGET_PATH' is not a valid directory."
        exit 1
    fi

# UNZIP MODE
elif [ "$COMMAND" == "unzip" ]; then
    # Path parameter is required
    if [ -z "$TARGET_PATH" ]; then
        print_error "Error: unzip command requires a path."
        print_heading "Usage: music-archive <path> unzip"
        exit 1
    fi

    # If target path is a specific zip file
    if [ -f "$TARGET_PATH" ] && [[ "$TARGET_PATH" == *.zip ]]; then
        extract_archive "$TARGET_PATH"

    # If target path is a directory, extract all zip files in it
    elif [ -d "$TARGET_PATH" ]; then
        print_info "Starting batch extraction process in: $TARGET_PATH"
        count=0
        for zip_file in "$TARGET_PATH"/*.zip; do
            [ -f "$zip_file" ] || continue

            extract_archive "$zip_file"
            if [ $? -eq 0 ]; then
                ((count++))
            fi
        done

        if [ $count -eq 0 ]; then
            print_warning "No zip files found in '$TARGET_PATH'."
        else
            print_heading "---------------------------------"
            print_success "Batch extraction complete. Processed $count archives."
        fi

    else
        print_error "Error: '$TARGET_PATH' is not a valid directory or zip file."
        exit 1
    fi

# SINGLE ARCHIVE MODE
elif [ -f "$TARGET_PATH" ] && [[ "$TARGET_PATH" == *.zip ]] && [ -z "$COMMAND" ]; then
    extract_archive "$TARGET_PATH"

else
    print_error "Error: Invalid arguments."
    print_usage
    exit 1
fi
