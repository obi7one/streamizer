#!/bin/bash

DRY_RUN=0

show_help() {
cat << EOF

Streamizer – Media Container Streaming Optimizer

Streamizer optimizes video containers for smoother streaming without
re-encoding media streams.

Supported formats:
  MP4  -> Moves the 'moov atom' to the beginning of the file (faststart).
  MKV  -> Rebuilds Matroska seek indexes (cues) only if not already present.

Dry-run mode (--dry-run):
  • Shows which files would be processed without modifying them.

Requirements:
  - ffmpeg
  - ffprobe
  - mkvmerge (from MKVToolNix)

Usage:
  Streamizer [--dry-run] <file_or_directory>

Examples:
  Streamizer "/Volumes/plexmedia/movies"
  Streamizer --dry-run "/Users/username/Desktop/Ponyo.mp4"

EOF
}

check_dependencies() {
    missing=0
    for cmd in ffmpeg ffprobe mkvmerge; do
        if ! command -v $cmd >/dev/null 2>&1; then
            echo "Error: '$cmd' is not installed or not in PATH."
            missing=1
        fi
    done
    if [ $missing -eq 1 ]; then
        echo
        echo "Please install required tools before running Streamizer."
        echo "FFmpeg: https://ffmpeg.org"
        echo "MKVToolNix: https://mkvtoolnix.download"
        exit 1
    fi
}

process_file() {
    local file="$1"
    local ext="${file##*.}"

    echo
    echo "Processing: $file"

    if [[ "$ext" == "mp4" ]]; then
        moov=$(ffprobe -v trace "$file" 2>&1 | grep -m 1 "type:'moov'")
        if [[ "$moov" == *"offset: 0"* ]]; then
            echo "MP4 already optimized. Skipping."
            return
        fi
        echo "MP4 needs faststart."
        if [[ $DRY_RUN -eq 0 ]]; then
            tmp="$(dirname "$file")/.tmp_$(basename "$file")"
            ffmpeg -loglevel error -i "$file" -map 0 -c copy -movflags +faststart "$tmp"
            if [ $? -eq 0 ]; then mv "$tmp" "$file"; echo "Done."; else echo "Error processing file."; rm -f "$tmp"; fi
        fi

    elif [[ "$ext" == "mkv" ]]; then
        cues=$(mkvmerge -i "$file" 2>/dev/null | grep -i "cues")
        if [[ "$cues" != "" ]]; then
            echo "MKV already has cues. Skipping."
            return
        fi
        echo "MKV needs cue rebuild."
        if [[ $DRY_RUN -eq 0 ]]; then
            tmp="$(dirname "$file")/.tmp_$(basename "$file")"
            mkvmerge -o "$tmp" "$file" >/dev/null 2>&1
            if [ $? -eq 0 ]; then mv "$tmp" "$file"; echo "Done."; else echo "Error processing file."; rm -f "$tmp"; fi
        fi

    else
        echo "Unsupported file type. Skipping."
    fi
}

# parse arguments
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=1
    shift
fi

if [ -z "$1" ]; then
    show_help
    exit 0
fi

check_dependencies

if [ -f "$1" ]; then
    process_file "$1"
elif [ -d "$1" ]; then
    find "$1" \( -iname "*.mp4" -o -iname "*.mkv" \) -type f | while read -r file; do
        process_file "$file"
    done
else
    echo "Error: '$1' is not a valid file or directory."
    exit 1
fi

if [[ $DRY_RUN -eq 1 ]]; then
    echo
    echo "Dry-run complete. No files were modified."
fi
