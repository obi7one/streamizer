# Streamizer

Streamizer is a lightweight macOS command-line utility that optimizes MP4 and MKV containers for smoother streaming without re-encoding the media streams.

## Status

Completed

## Features

- Optimizes MP4 files using FFmpeg faststart.
- Rebuilds MKV seek indexes (cues) when needed.
- Detects files that are already optimized and skips them.
- Processes either individual files or entire directories recursively.
- Supports a dry-run mode to preview changes without modifying files.
- Preserves the original video and audio streams.

## Requirements

- macOS
- FFmpeg (`ffmpeg` and `ffprobe`)
- MKVToolNix (`mkvmerge`)

## Usage

Process a file:

```bash
./streamizer.sh "/path/to/file.mkv"
```

Process a directory recursively:

```bash
./streamizer.sh "/path/to/media"
```

Preview what would be processed without modifying files:

```bash
./streamizer.sh --dry-run "/path/to/media"
```

## How It Works

For MP4 files, Streamizer checks the location of the `moov` atom and applies FFmpeg `+faststart` when necessary.

For MKV files, it checks whether cues are already present. If they are missing, MKVToolNix rebuilds the container indexes without re-encoding the media.

Temporary files are created in the same directory as the source file and replace the original only after successful processing.

## Project Structure

```text
streamizer/
├── .gitignore
├── README.md
├── streamizer.sh
└── Streamizer.dmg
```

## Design Notes

Streamizer operates at the container level. It does not re-encode video or audio, so the media streams themselves remain unchanged.

The script is designed to be safe to run repeatedly: files that are already optimized are skipped.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for the full license text.
