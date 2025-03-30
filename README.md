# Ultimate Command Recorder Documentation

## Overview

Ultimate Command Recorder is a powerful Bash script that records terminal sessions, captures all user commands and file system changes, and allows perfect reproduction of the session on other systems. The recorder creates comprehensive self-contained recordings that can be shared, replayed, and used for training, documentation, or troubleshooting purposes.

## Features

- Records all terminal commands with exact timing
- Captures all file system changes, including file creations and modifications
- Provides two replay methods:
  - Command playback with visual feedback
  - Full terminal session replay with exact keystroke timing
- Automatically pre-populates files for editors like nano, vim, and vi
- Captures content for files created or modified during the session
- Creates self-contained, portable recordings that can be moved between systems
- Offers debug logging for troubleshooting

## Installation

No installation is required. Simply download the `ultimate_recorder.sh` script, make it executable, and run it:

```bash
chmod +x ultimate_recorder.sh
./ultimate_recorder.sh
```

## Usage

### Starting a Recording Session

Run the script without arguments to start recording with all features enabled:

```bash
./ultimate_recorder.sh
```

This will start a new terminal session with a green `record>` prompt, indicating that recording is active.

### Command Line Options

The script supports several command-line options:

```
Usage: ./ultimate_recorder.sh [options]

Options:
  --no-full      Don't record full terminal session (keystrokes)
  --no-commands  Don't record commands for script generation
  -h, --help     Display this help message
```

### During Recording

While recording is active:

1. Type commands as you normally would
2. All keystrokes and screen output will be recorded
3. All file operations will be captured, including:
   - File creations
   - File modifications
   - Content changes in text editors
4. To stop recording, type `stoprecord` and press Enter

### File Editing Support

The recorder has special handling for text editors:

- Automatically detects when you use `nano`, `vi`, or `vim`
- Captures the content of files before and after editing
- Stores copies of edited files for replay
- During replay, pre-populates files with the correct content before opening in editors

## Output

After recording completes, a new directory is created in the current working directory named `recorded_session_YYYYMMDD_HHMMSS`. This directory contains:

| File/Directory | Purpose |
|----------------|---------|
| `replay_commands.sh` | Script to replay just the commands with file integration |
| `replay_full_session.sh` | Script to replay the full terminal session with exact timing |
| `files/` | Directory containing copies of all file content |
| `file_mapping.txt` | Maps original file paths to their saved contents |
| `command_log.txt` | Detailed log of executed commands |
| `tty_recording.tty` | Raw terminal recording data |
| `tty_timing.tim` | Timing data for the terminal recording |
| `debug.log` | Debug information (can be deleted) |
| `README.txt` | Instructions for usage |

## Replay Methods

### Command Replay

To replay just the commands (with file system integration):

```bash
./recorded_session_YYYYMMDD_HHMMSS/replay_commands.sh
```

This will:
- Restore all files created during the recording
- Execute each command with visual feedback
- Pre-populate files for editor commands
- Show command execution status

### Full Session Replay

To replay the full terminal session:

```bash
./recorded_session_YYYYMMDD_HHMMSS/replay_full_session.sh
```

This will:
- Restore all files created during the recording
- Replay the exact terminal session with original keystroke timing
- Show EVERYTHING exactly as it happened during recording

## Portability

The recording directory is completely self-contained and portable:

1. Copy the entire `recorded_session_YYYYMMDD_HHMMSS` directory to any system
2. Make scripts executable (if needed): 
   ```bash
   chmod +x replay_commands.sh replay_full_session.sh
   ```
3. Run either replay script as described above

## Technical Details

### File Tracking Mechanism

The recorder uses multiple approaches to ensure all file changes are captured:

1. Directory snapshots before and after operations
2. Direct tracking of editor commands
3. File state hashing for change detection
4. Exit traps for nano editor state capture

### Mapping File Format

The `file_mapping.txt` file uses a simple format:
```
/absolute/path/to/file1:content_file1.txt
/absolute/path/to/file2:content_file2.txt
```

This maps original file paths to their saved content in the `files/` directory.

## Limitations

- Works best in Bash environments
- Limited support for graphical editors
- Does not track remote file operations

## Troubleshooting

### Debug Log

For troubleshooting, check the `debug.log` file in the recording directory. It contains detailed information about:

- Command detection
- File tracking
- Content capture
- Script generation

### Common Issues

1. **Missing files during replay**:
   - Check that the `file_mapping.txt` contains entries for all files
   - Ensure the `files/` directory contains all content files

2. **Editor files not pre-populated**:
   - Check editor command format in the recording
   - Verify file paths in `file_mapping.txt`

3. **Command replay errors**:
   - Ensure dependencies installed on the replay system
   - Check for system-specific commands that may not be portable

## Advanced Usage

### Recording Specific Work Environments

For complex environments, consider running from a script that sets up the environment first:

```bash
#!/bin/bash
# Set up the environment
export PATH=/custom/path:$PATH
cd /specific/work/directory

# Start recording
./path/to/ultimate_recorder.sh
```

### Creating Instructional Sessions

For creating tutorials:
1. Plan your commands beforehand
2. Record a clean session with good comments
3. Distribute the session directory 
4. Recipients can use either replay method to follow along

## License and Contributions

This script is provided as-is for general use. Contributions and improvements are welcome.

## About

Ultimate Command Recorder was created to provide a comprehensive solution for terminal session recording with full file system integration, allowing perfect reproduction of terminal sessions across different environments and systems.
