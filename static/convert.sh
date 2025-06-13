#!/bin/bash

# Directory containing the videos
VIDEO_DIR="./policy_view_videos"

# Check if the directory exists
if [ ! -d "$VIDEO_DIR" ]; then
    echo "Error: Directory $VIDEO_DIR does not exist."
    exit 1
fi

# Check if FFmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: FFmpeg is not installed. Please install it first."
    echo "On macOS: brew install ffmpeg"
    echo "On Ubuntu: sudo apt-get install ffmpeg"
    exit 1
fi

# Check if ffprobe is installed
if ! command -v ffprobe &> /dev/null; then
    echo "Error: ffprobe is not installed. Please install it first (usually included with FFmpeg)."
    exit 1
fi

# Create a logs directory for FFmpeg error logs
LOG_DIR="./ffmpeg_logs"
mkdir -p "$LOG_DIR"

# Find all .mp4 files, excluding those ending with _converted.mp4
find "$VIDEO_DIR" -type f -name "*.mp4" ! -name "*_converted.mp4" | while read -r ORIGINAL_FILE; do
    # Check if the file still exists
    if [ ! -f "$ORIGINAL_FILE" ]; then
        echo "Warning: File not found: $ORIGINAL_FILE. Skipping."
        continue
    fi

    # Get the directory and base file name
    DIR=$(dirname "$ORIGINAL_FILE")
    BASENAME=$(basename "$ORIGINAL_FILE" .mp4)
    
    # Append _converted to the file name
    OUTPUT_FILE="$DIR/${BASENAME}_converted.mp4"
    
    # Create a unique log file for this conversion
    LOG_FILE="$LOG_DIR/$(echo "$BASENAME" | sed 's/[=:]/_/g')_$(date +%s).log"
    
    echo "Processing: $ORIGINAL_FILE"
    echo "Output: $OUTPUT_FILE"
    echo "Log: $LOG_FILE"
    
    # Convert the video to H.264/AAC with faststart, disable stdin, and log errors
    ffmpeg -nostdin -y -i "$ORIGINAL_FILE" -c:v libx264 -c:a aac -strict -2 -movflags +faststart "$OUTPUT_FILE" 2> "$LOG_FILE"
    
    # Check if conversion was successful (exit code 0 and output file exists/non-empty)
    if [ $? -eq 0 ] && [ -s "$OUTPUT_FILE" ]; then
        echo "Conversion successful for $ORIGINAL_FILE"
        
        # Verify the output file is playable
        if ffprobe "$OUTPUT_FILE" >/dev/null 2>&1; then
            echo "Output file is valid. Deleting original: $ORIGINAL_FILE"
            rm "$ORIGINAL_FILE"
        else
            echo "Error: Output file $OUTPUT_FILE is not valid. Check $LOG_FILE for details."
            rm -f "$OUTPUT_FILE"
        fi
    else
        echo "Error: Conversion failed for $ORIGINAL_FILE. Check $LOG_FILE for details."
        rm -f "$OUTPUT_FILE"
    fi
done

echo "Conversion and replacement complete."
echo "FFmpeg error logs are saved in $LOG_DIR"