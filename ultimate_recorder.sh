#!/bin/bash
#
# Ultimate Command Recorder - Records ALL user actions with file system integration
#

# Configuration
OUTPUT_DIR="./recorded_session_$(date +"%Y%m%d_%H%M%S")"
OUTPUT_SCRIPT="${OUTPUT_DIR}/replay_commands.sh"
RECORD_LOG="${OUTPUT_DIR}/command_log.txt"
FILE_CONTENT_DIR="${OUTPUT_DIR}/files"
TTY_RECORDING="${OUTPUT_DIR}/tty_recording.tty"
TTY_TIMING="${OUTPUT_DIR}/tty_timing.tim"
FULL_SESSION_SCRIPT="${OUTPUT_DIR}/replay_full_session.sh"
FILE_MAPPER="${OUTPUT_DIR}/file_mapping.txt"
TEMP_DIR="${OUTPUT_DIR}/.temp"
DEBUG_LOG="${OUTPUT_DIR}/debug.log"

# Create output directories
mkdir -p "$OUTPUT_DIR"
mkdir -p "$FILE_CONTENT_DIR"
mkdir -p "$TEMP_DIR"

# Set up debugging
touch "$DEBUG_LOG"
echo "# Debug log started at $(date)" > "$DEBUG_LOG"

# Handle command line arguments
RECORD_FULL_SESSION=1
RECORD_COMMANDS=1

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --no-full)
            RECORD_FULL_SESSION=0
            shift
            ;;
        --no-commands)
            RECORD_COMMANDS=0
            shift
            ;;
        -h|--help)
            echo "Ultimate Command Recorder - Records commands with file system integration"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --no-full      Don't record full terminal session (keystrokes)"
            echo "  --no-commands  Don't record commands for script generation"
            echo "  -h, --help     Display this help message"
            echo ""
            echo "During recording:"
            echo "  - Type commands as normal"
            echo "  - ALL keystrokes and screen output will be recorded"
            echo "  - All file operations will be captured and reproduced exactly"
            echo "  - Type 'stoprecord' to stop recording"
            echo ""
            echo "Output will be in: $OUTPUT_DIR"
            echo "Can be easily moved to another system (all paths are relative)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Initialize file mapping
touch "$FILE_MAPPER"

# Initialize command script if needed
if [ $RECORD_COMMANDS -eq 1 ]; then
    cat > "$OUTPUT_SCRIPT" << 'EOF'
#!/bin/bash
#
# Recorded command script with file content restore
# Created: $(date)
#

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FILES_DIR="${SCRIPT_DIR}/files"
FILE_MAPPER="${SCRIPT_DIR}/file_mapping.txt"

# Function to restore all captured files before playback
restore_all_files() {
    echo "Restoring files created during the session..."
    
    if [ -f "$FILE_MAPPER" ]; then
        while IFS=: read -r file_path content_file; do
            if [ -n "$file_path" ] && [ -n "$content_file" ] && [ -f "$FILES_DIR/$content_file" ]; then
                echo "  → Restoring: $file_path"
                
                # Create directory if needed
                mkdir -p "$(dirname "$file_path")"
                
                # Copy content to the file
                cat "$FILES_DIR/$content_file" > "$file_path"
            fi
        done < "$FILE_MAPPER"
        
        echo "All files restored successfully."
    else
        echo "No file mapping found, continuing without restoration."
    fi
}

# Function to run commands with visual feedback
run_command() {
    echo -e "\033[1;36m>> Running: $1\033[0m"
    
    # Special handling for editors to pre-populate files
    if [[ "$1" =~ ^(nano|vi|vim) ]]; then
        prepare_editor_files "$1"
    fi
    
    # Run the actual command
    eval "$1"
    local status=$?
    
    if [ $status -eq 0 ]; then
        echo -e "\033[1;32m>> Command completed successfully\033[0m"
    else
        echo -e "\033[1;31m>> Command failed with status $status\033[0m"
    fi
    echo ""
    sleep 1
}

# Function to create/edit file with content
edit_file() {
    local file="$1"
    local content_file="$2"
    
    # Create directory if needed
    mkdir -p "$(dirname "$file")"
    
    echo -e "\033[1;36m>> Creating/editing file: $file\033[0m"
    
    # Check if content file exists
    if [ ! -f "$content_file" ]; then
        echo -e "\033[1;31mError: Content file not found: $content_file\033[0m"
        return 1
    fi
    
    # Copy content to the file
    cat "$content_file" > "$file"
    
    echo -e "\033[1;32m>> File created/updated\033[0m"
    echo ""
}

# Function to prepare files for editors
prepare_editor_files() {
    local cmd="$1"
    
    # Extract the filename from the command
    local file_path=$(echo "$cmd" | awk '{for(i=2;i<=NF;i++) if(!match($i, /^-/)) {print $i; exit}}')
    
    # Skip if no filename
    if [ -z "$file_path" ]; then
        return
    fi
    
    # Handle relative paths
    if [[ "$file_path" != /* ]]; then
        file_path="$PWD/$file_path"
    fi
    
    # Check if we have content for this file in our mapping
    if [ -f "$FILE_MAPPER" ]; then
        local content_file=$(grep "^$file_path:" "$FILE_MAPPER" | cut -d: -f2)
        if [ -n "$content_file" ] && [ -f "$FILES_DIR/$content_file" ]; then
            # Create directory structure if needed
            mkdir -p "$(dirname "$file_path")"
            
            # Pre-populate the file with the content
            echo -e "\033[1;33m>> Pre-populating file for editor: $file_path\033[0m"
            cat "$FILES_DIR/$content_file" > "$file_path"
        fi
    fi
}

EOF

    # Initialize command log
    echo "# Command Recording Session - $(date)" > "$RECORD_LOG"
    echo "# ----------------------------------------" >> "$RECORD_LOG"
fi

# Create a shell script that can replay the full TTY session with file system integration
if [ $RECORD_FULL_SESSION -eq 1 ]; then
    cat > "$FULL_SESSION_SCRIPT" << 'EOF'
#!/bin/bash
#
# Full TTY session replay script with file system integration
# Recorded on: $(date)
#

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TTY_RECORDING="${SCRIPT_DIR}/tty_recording.tty"
TTY_TIMING="${SCRIPT_DIR}/tty_timing.tim"
FILES_DIR="${SCRIPT_DIR}/files"
FILE_MAPPER="${SCRIPT_DIR}/file_mapping.txt"

# Check if files exist
if [ ! -f "$TTY_RECORDING" ] || [ ! -f "$TTY_TIMING" ]; then
    echo "Error: Recording files not found!"
    echo "Expected files in: $SCRIPT_DIR"
    exit 1
fi

# Function to restore all captured files before playback
restore_all_files() {
    echo "Restoring files created during the session..."
    
    if [ -f "$FILE_MAPPER" ]; then
        while IFS=: read -r file_path content_file; do
            if [ -n "$file_path" ] && [ -n "$content_file" ] && [ -f "$FILES_DIR/$content_file" ]; then
                echo "  → Restoring: $file_path"
                
                # Create directory if needed
                mkdir -p "$(dirname "$file_path")"
                
                # Copy content to the file
                cat "$FILES_DIR/$content_file" > "$file_path"
            fi
        done < "$FILE_MAPPER"
        
        echo "All files restored successfully."
    else
        echo "No file mapping found, continuing without restoration."
    fi
}

# Restore files before playback
restore_all_files

echo "Starting full TTY session replay..."
echo "Press Ctrl+C to exit at any time"
echo 
echo "Note: This will show EVERYTHING exactly as it happened during recording,"
echo "including all keystrokes, timing, and screen output."
echo 
echo "Starting replay in 3 seconds..."
sleep 3

scriptreplay --timing="$TTY_TIMING" "$TTY_RECORDING"

echo "Playback completed."
EOF

    chmod +x "$FULL_SESSION_SCRIPT"
fi

# Display the welcome message
echo "=================================================="
echo "Ultimate Command Recording started"
echo "All files will be saved to: $OUTPUT_DIR"
if [ $RECORD_COMMANDS -eq 1 ]; then
    echo "Recording commands to: $OUTPUT_SCRIPT"
fi
if [ $RECORD_FULL_SESSION -eq 1 ]; then
    echo "Recording full TTY session with file system integration"
    echo "Full session replay: $FULL_SESSION_SCRIPT"
fi
echo "Type commands as normal"
echo "Type 'stoprecord' to stop recording"
echo "=================================================="
echo ""

# Track files being edited and commands
declare -A tracked_files
declare -A command_hash  # Use a hash table to track unique commands
declare -a commands

# Function to take a snapshot of a directory
snapshot_directory() {
    local dir="$1"
    local snapshot_file="$2"
    
    if [ -d "$dir" ]; then
        find "$dir" -type f -exec stat -c "%n %Y %s" {} \; | sort > "$snapshot_file"
    fi
}

# Function to capture file state before editing
capture_file_before() {
    local file_path="$1"
    local editor_cmd="$2"
    
    echo "DEBUG: Capturing file state before editing: $file_path" >> "$DEBUG_LOG"
    
    if [ -f "$file_path" ]; then
        # Save file content before editing if it exists
        local file_hash=$(md5sum "$file_path" | cut -d' ' -f1)
        local before_file="${FILE_CONTENT_DIR}/before_${file_hash}_$(basename "$file_path")"
        cp "$file_path" "$before_file"
        tracked_files["$file_path"]="$before_file"
        echo "DEBUG: Saved before state to: $before_file" >> "$DEBUG_LOG"
        echo "# Captured state of $file_path before editing" >> "$RECORD_LOG"
    fi
    
    # Take a directory snapshot before editing
    local dir_to_monitor=$(dirname "$file_path")
    snapshot_directory "$dir_to_monitor" "${TEMP_DIR}/snapshot_before_$(echo "$dir_to_monitor" | tr '/' '_')"
    echo "DEBUG: Created directory snapshot for: $dir_to_monitor" >> "$DEBUG_LOG"
}

# Function to add file to mapping
add_file_mapping() {
    local file_path="$1"
    local content_basename="$2"
    
    echo "DEBUG: Adding file mapping: $file_path -> $content_basename" >> "$DEBUG_LOG"
    
    # Add to mapping file
    echo "$file_path:$content_basename" >> "$FILE_MAPPER"
}

# Function to find changed or new files after editing
find_changed_files() {
    local dir_to_check="$1"
    local before_snapshot="${TEMP_DIR}/snapshot_before_$(echo "$dir_to_check" | tr '/' '_')"
    local after_snapshot="${TEMP_DIR}/snapshot_after_$(echo "$dir_to_check" | tr '/' '_')"
    
    echo "DEBUG: Checking directory for changes: $dir_to_check" >> "$DEBUG_LOG"
    
    # Capture current state
    snapshot_directory "$dir_to_check" "$after_snapshot"
    
    # If we don't have a before snapshot, we can't compare
    if [ ! -f "$before_snapshot" ]; then
        echo "DEBUG: No before snapshot exists for directory: $dir_to_check" >> "$DEBUG_LOG"
        return
    fi
    
    # Find new or modified files
    local changed_files=$(comm -13 <(sort "$before_snapshot") <(sort "$after_snapshot") | awk '{print $1}')
    
    echo "DEBUG: Changed files detected: $changed_files" >> "$DEBUG_LOG"
    
    # Process each changed file
    if [ -n "$changed_files" ]; then
        echo "$changed_files" | while read -r file; do
            if [ -f "$file" ]; then
                echo "DEBUG: Processing changed file: $file" >> "$DEBUG_LOG"
                
                # Save the content
                local content_basename="content_$(basename "$file")"
                local content_file="${FILE_CONTENT_DIR}/${content_basename}"
                cp "$file" "$content_file"
                
                echo "DEBUG: Copied file to: $content_file" >> "$DEBUG_LOG"
                
                # Store the mapping
                tracked_files["$file,content"]="$content_file"
                
                # Add to mapping file
                add_file_mapping "$file" "$content_basename"
                
                echo "# Captured changes to $file detected by directory monitoring" >> "$RECORD_LOG"
            fi
        done
    else
        echo "DEBUG: No changes detected in directory" >> "$DEBUG_LOG"
    fi
}

# Function to capture file state after editing
capture_file_after() {
    local file_path="$1"
    
    echo "DEBUG: Attempting to capture changes for file: $file_path" >> "$DEBUG_LOG"
    
    if [ -f "$file_path" ]; then
        # Check if file was tracked before editing
        if [ -n "${tracked_files[$file_path]}" ]; then
            local before_hash=$(md5sum "${tracked_files[$file_path]}" | cut -d' ' -f1)
            local after_hash=$(md5sum "$file_path" | cut -d' ' -f1)
            
            echo "DEBUG: Before hash: $before_hash" >> "$DEBUG_LOG"
            echo "DEBUG: After hash: $after_hash" >> "$DEBUG_LOG"
            
            if [ "$before_hash" != "$after_hash" ]; then
                # File was changed, save the new content
                local content_basename="content_$(basename "$file_path")"
                local content_file="${FILE_CONTENT_DIR}/${content_basename}"
                cp "$file_path" "$content_file"
                
                echo "DEBUG: Copied changed file to: $content_file" >> "$DEBUG_LOG"
                
                # Store the mapping for later
                tracked_files["$file_path,content"]="$content_file"
                
                # Add to mapping file
                add_file_mapping "$file_path" "$content_basename"
                
                echo "# Captured changes to $file_path after editing" >> "$RECORD_LOG"
            else
                echo "DEBUG: No changes detected in file" >> "$DEBUG_LOG"
                echo "# No changes detected in $file_path" >> "$RECORD_LOG"
            fi
        else
            # New file was created
            echo "DEBUG: New file detected: $file_path" >> "$DEBUG_LOG"
            local content_basename="content_$(basename "$file_path")"
            local content_file="${FILE_CONTENT_DIR}/${content_basename}"
            cp "$file_path" "$content_file"
            
            echo "DEBUG: Copied new file to: $content_file" >> "$DEBUG_LOG"
            
            # Store the mapping for later
            tracked_files["$file_path,content"]="$content_file"
            
            # Add to mapping file
            add_file_mapping "$file_path" "$content_basename"
            
            echo "# Captured new file $file_path" >> "$RECORD_LOG"
        fi
    else
        echo "DEBUG: File does not exist: $file_path" >> "$DEBUG_LOG"
    fi
    
    # Check for other files that might have been created or modified
    local dir_to_check=$(dirname "$file_path")
    echo "DEBUG: Checking directory for changes: $dir_to_check" >> "$DEBUG_LOG"
    find_changed_files "$dir_to_check"
}

# Function to add a command to our list (without duplicates)
add_command() {
    local cmd="$1"
    
    # Skip empty or whitespace-only commands
    if [[ -z "${cmd// /}" ]]; then
        return
    fi
    
    # Skip commands we've already seen (using hash to avoid duplicates)
    local cmd_hash=$(echo "$cmd" | md5sum | cut -d' ' -f1)
    
    if [ -z "${command_hash[$cmd_hash]}" ]; then
        command_hash[$cmd_hash]="1"
        commands+=("$cmd")
        echo "DEBUG: Added command to list: $cmd" >> "$DEBUG_LOG"
        echo "# $(date): $cmd" >> "$RECORD_LOG"
    fi
}

# Export the command storage directory
export ULTIMATE_RECORDER_DIR="$OUTPUT_DIR"
export ULTIMATE_RECORDER_COMMANDS_FILE="${TEMP_DIR}/commands_list"
export ULTIMATE_RECORDER_LASTFILE="${TEMP_DIR}/last_edited_file"
export FILE_CONTENT_DIR
export TEMP_DIR
export FILE_MAPPER
export DEBUG_LOG

# Create a script to capture commands in the script session
cat > "${TEMP_DIR}/recorder_helper.sh" << 'EOF'
#!/bin/bash

# Previous command tracking to avoid duplicates
last_command=""

capture_command() {
    local cmd="$1"
    
    # Trim whitespace
    cmd=$(echo "$cmd" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Skip empty commands and duplicates
    if [[ -z "$cmd" || "$cmd" == "$last_command" ]]; then
        return
    fi
    
    # Debug output
    echo "DEBUG: Captured command: $cmd" >> "$ULTIMATE_RECORDER_DIR/debug.log"
    
    # Update last command
    last_command="$cmd"
    
    # Record command to file
    echo "$cmd" >> "$ULTIMATE_RECORDER_COMMANDS_FILE"
    
    # Check for editor commands
    if [[ "$cmd" =~ ^(nano|vim|vi) ]]; then
        # Extract file path, handle more complex commands like 'nano -w filename'
        local file_path=$(echo "$cmd" | awk '{for(i=2;i<=NF;i++) if(!match($i, /^-/)) {print $i; exit}}')
        
        # Handle relative paths
        if [[ "$file_path" != /* ]]; then
            file_path="$PWD/$file_path"
        fi
        
        echo "DEBUG: Editor detected, file path: $file_path" >> "$ULTIMATE_RECORDER_DIR/debug.log"
        
        # Save for post-processing
        echo "$file_path" > "$ULTIMATE_RECORDER_LASTFILE"
        
        # Add special marker to trigger file capture on exit
        export NANO_EDITING_FILE="$file_path"
    fi
}

# Set up an exit trap for nano to capture file on exit
trap_exit() {
    if [ -n "$NANO_EDITING_FILE" ] && [ -f "$NANO_EDITING_FILE" ]; then
        echo "DEBUG: Editor exit trap, capturing file: $NANO_EDITING_FILE" >> "$ULTIMATE_RECORDER_DIR/debug.log"
        
        # For nano specific - capture the file directly after editor exit
        local content_basename="content_$(basename "$NANO_EDITING_FILE")"
        local content_file="$FILE_CONTENT_DIR/$content_basename"
        
        # Copy the file content
        cp "$NANO_EDITING_FILE" "$content_file"
        echo "DEBUG: Copied file to: $content_file" >> "$ULTIMATE_RECORDER_DIR/debug.log"
        
        # Add to mapping file directly
        echo "$NANO_EDITING_FILE:$content_basename" >> "$FILE_MAPPER"
        echo "DEBUG: Added mapping directly: $NANO_EDITING_FILE -> $content_basename" >> "$ULTIMATE_RECORDER_DIR/debug.log"
        
        # Clear the variable
        NANO_EDITING_FILE=""
    fi
}

trap trap_exit EXIT

# Set up command tracking
PROMPT_COMMAND="capture_command \"\$(history 1 | sed 's/^[ 0-9]*//;s/^[[:space:]]*//;s/^[0-9]* //');\""
EOF

chmod +x "${TEMP_DIR}/recorder_helper.sh"

# Clean slate for command file
echo "" > "$ULTIMATE_RECORDER_COMMANDS_FILE"

# Create a custom .bashrc for our recording session
cat > "${TEMP_DIR}/recording_bashrc" << EOF
# Source the user's actual .bashrc if it exists
if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
fi

# Set up record prompt
PS1="\[\033[1;32m\]record>\[\033[0m\] "

# Set up history 
HISTCONTROL=ignoredups:erasedups
HISTSIZE=10000

# Source our helper script
source "${TEMP_DIR}/recorder_helper.sh"

# Define stoprecord function
stoprecord() {
    echo "Stopping recording..."
    exit 0
}
EOF

# Start the recording session
if [ $RECORD_FULL_SESSION -eq 1 ]; then
    # Use script to record the full terminal session with timing
    script -c "bash --rcfile ${TEMP_DIR}/recording_bashrc" -t"$TTY_TIMING" "$TTY_RECORDING"
else
    # Just use a custom bash session to record commands
    bash --rcfile "${TEMP_DIR}/recording_bashrc"
fi

# Now the recording is done, process the commands list
if [ -f "$ULTIMATE_RECORDER_COMMANDS_FILE" ]; then
    echo "DEBUG: Processing commands list after recording" >> "$DEBUG_LOG"
    # Read the commands file and process each line
    while IFS= read -r cmd; do
        # Skip the 'stoprecord' command and empty lines
        if [[ "$cmd" == "stoprecord" || -z "${cmd// /}" ]]; then
            continue
        fi
        
        echo "DEBUG: Processing command: $cmd" >> "$DEBUG_LOG"
        
        # Process editor commands
        if [[ "$cmd" =~ ^(nano|vim|vi) ]]; then
            # Extract file path
            file_path=$(echo "$cmd" | awk '{for(i=2;i<=NF;i++) if(!match($i, /^-/)) {print $i; exit}}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            # Handle relative paths
            if [[ "$file_path" != /* ]]; then
                file_path="$PWD/$file_path"
            fi
            
            echo "DEBUG: Detected editor command with file: $file_path" >> "$DEBUG_LOG"
            
            # Capture file changes if it exists
            if [ -f "$file_path" ]; then
                # Save the content
                content_basename="content_$(basename "$file_path")"
                content_file="${FILE_CONTENT_DIR}/${content_basename}"
                cp "$file_path" "$content_file"
                
                echo "DEBUG: Copied file to: $content_file" >> "$DEBUG_LOG"
                
                # Store the mapping
                tracked_files["$file_path,content"]="$content_file"
                
                # Add to mapping file
                add_file_mapping "$file_path" "$content_basename"
                
                echo "# Captured content of $file_path from editor command" >> "$RECORD_LOG"
            else
                echo "DEBUG: File does not exist: $file_path" >> "$DEBUG_LOG"
            fi
        fi
        
        # Add command to our list
        add_command "$cmd"
    done < "$ULTIMATE_RECORDER_COMMANDS_FILE"
fi

# Direct file check - ensuring all nano-edited files are captured
echo "DEBUG: Performing direct file check for editor commands" >> "$DEBUG_LOG"
if [ -f "$ULTIMATE_RECORDER_COMMANDS_FILE" ]; then
    # Find all nano commands
    grep "^nano" "$ULTIMATE_RECORDER_COMMANDS_FILE" | while read -r cmd; do
        # Extract file path
        file_path=$(echo "$cmd" | awk '{for(i=2;i<=NF;i++) if(!match($i, /^-/)) {print $i; exit}}')
        
        # Handle relative paths
        if [[ "$file_path" != /* ]]; then
            file_path="$PWD/$file_path"
        fi
        
        echo "DEBUG: Direct check for nano-edited file: $file_path" >> "$DEBUG_LOG"
        
        # If file exists, capture it
        if [ -f "$file_path" ]; then
            # Check if this file is already in the mapping
            if ! grep -q "^$file_path:" "$FILE_MAPPER"; then
                echo "DEBUG: Adding missing nano-edited file: $file_path" >> "$DEBUG_LOG"
                
                # Save the content
                content_basename="content_$(basename "$file_path")"
                content_file="${FILE_CONTENT_DIR}/${content_basename}"
                cp "$file_path" "$content_file"
                
                # Add to mapping file
                echo "$file_path:$content_basename" >> "$FILE_MAPPER"
                echo "DEBUG: Added mapping for nano-edited file: $file_path -> $content_basename" >> "$DEBUG_LOG"
            fi
        else
            echo "DEBUG: File does not exist during direct check: $file_path" >> "$DEBUG_LOG"
        fi
    done
fi

# Now create the script if needed
if [ $RECORD_COMMANDS -eq 1 ]; then
    echo "DEBUG: Creating replay script" >> "$DEBUG_LOG"
    # First, add file content copy checking
    cat >> "$OUTPUT_SCRIPT" << 'EOF'
# Setup - Checking if content files exist
echo "Checking for file content resources..."

# Check if files directory exists
if [ ! -d "$FILES_DIR" ]; then
    echo "Error: Files directory not found!"
    echo "Expected directory: $FILES_DIR"
    exit 1
fi

# Check if file mapping exists
if [ ! -f "$FILE_MAPPER" ]; then
    echo "Warning: File mapping not found. Some files may not be restored properly."
fi

# Restore all files before command playback
echo "Pre-restoring all files before command playback..."
restore_all_files

echo "All file content resources are available."
echo "Starting command playback..."

EOF

    # Now add all the commands to the script
    for cmd in "${commands[@]}"; do
        echo "DEBUG: Adding command to script: $cmd" >> "$DEBUG_LOG"
        echo "run_command \"$cmd\"" >> "$OUTPUT_SCRIPT"
    done

    # Add file edits after commands (for files that might not have been handled by the editor)
    for file_key in "${!tracked_files[@]}"; do
        if [[ "$file_key" == *",content" ]]; then
            file_path=${file_key%,content}
            content_file="${tracked_files[$file_key]}"
            content_basename=$(basename "$content_file")
            
            # Check if this file was already handled by an editor command
            if ! grep -q "^$file_path:" "$FILE_MAPPER"; then
                echo "DEBUG: Adding file edit command for: $file_path" >> "$DEBUG_LOG"
                # Add file restoration to the script
                echo "" >> "$OUTPUT_SCRIPT"
                echo "# Create/edit file: $file_path" >> "$OUTPUT_SCRIPT"
                echo "edit_file \"$file_path\" \"\$FILES_DIR/$content_basename\"" >> "$OUTPUT_SCRIPT"
                
                # Add to mapping file
                add_file_mapping "$file_path" "$content_basename"
            fi
        fi
    done

    # Add final message
    cat >> "$OUTPUT_SCRIPT" << 'EOF'

echo "Script playback completed!"
EOF

    # Make script executable
    chmod +x "$OUTPUT_SCRIPT"
fi

# Verify file_mapping.txt has entries
echo "DEBUG: Checking file_mapping.txt for entries" >> "$DEBUG_LOG"
if [ -f "$FILE_MAPPER" ]; then
    mapping_count=$(wc -l < "$FILE_MAPPER")
    echo "DEBUG: file_mapping.txt has $mapping_count entries" >> "$DEBUG_LOG"
    
    if [ "$mapping_count" -eq 0 ]; then
        echo "WARNING: file_mapping.txt is empty despite command processing" >> "$DEBUG_LOG"
        
        # Last resort - try to find all files in the current directory structure
        # that were created/modified during the recording session
        echo "DEBUG: Attempting last resort file discovery" >> "$DEBUG_LOG"
        
        # Find files modified during our session
        start_time=$(date -d "-1 hour" +%s)  # Assume session was in the last hour
        find . -type f -newer "$OUTPUT_DIR" | while read -r file; do
            # Skip our own files
            if [[ "$file" == "$OUTPUT_DIR"* ]]; then
                continue
            fi
            
            echo "DEBUG: Found modified file: $file" >> "$DEBUG_LOG"
            
            # Save the content
            content_basename="content_$(basename "$file")"
            content_file="${FILE_CONTENT_DIR}/${content_basename}"
            cp "$file" "$content_file"
            
            # Add to mapping file
            add_file_mapping "$file" "$content_basename"
            echo "DEBUG: Added mapping for discovered file: $file -> $content_basename" >> "$DEBUG_LOG"
        done
    fi
fi

# Create a README file with instructions
cat > "${OUTPUT_DIR}/README.txt" << EOF
Ultimate Command Recording Session
=================================
Recorded on: $(date)

This directory contains a complete recording of a terminal session
with full file system integration.

Contents:
---------
1. replay_commands.sh - Script to replay the recorded commands
2. replay_full_session.sh - Script to replay the FULL terminal session
3. files/ - Directory containing saved file contents
4. file_mapping.txt - Maps original file paths to their saved contents
5. command_log.txt - Detailed log of executed commands
6. tty_recording.tty - Raw terminal recording data
7. tty_timing.tim - Timing data for the terminal recording
8. debug.log - Debugging information (can be deleted)

Usage:
------
1. To replay just the commands (with file operations):
   ./replay_commands.sh

2. To replay the FULL terminal session (with pre-populated files):
   ./replay_full_session.sh

Transfer Instructions:
---------------------
To transfer this session to another system:
1. Copy this ENTIRE directory to the target system
2. Make sure the scripts are executable
   chmod +x replay_commands.sh replay_full_session.sh
3. Run either script as described above

Note: All paths are relative, so the directory structure should be maintained.
EOF

# Clean up temporary files
rm -rf "${TEMP_DIR}"

# Final message
echo "=================================================="
echo "Recording finished!"
echo "All files saved to: $OUTPUT_DIR"
echo ""
echo "This directory can be copied to any system and run from there."
echo "All paths are relative, so no path adjustment is needed."
echo ""

if [ $RECORD_COMMANDS -eq 1 ]; then
    echo "To replay commands: ./$OUTPUT_DIR/replay_commands.sh"
    echo "  - Commands will be replayed with file system integration"
    echo "  - Files will be pre-populated for editors"
fi

if [ $RECORD_FULL_SESSION -eq 1 ]; then
    echo "To replay full terminal session: ./$OUTPUT_DIR/replay_full_session.sh"
    echo "  - Session will be replayed with EXACT keystroke timing"
    echo "  - All files will be restored before playback"
fi

echo ""
echo "See $OUTPUT_DIR/README.txt for more information."
echo "=================================================="

exit 0
