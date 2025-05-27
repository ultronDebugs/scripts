#!/bin/bash

# Usage: ./hls_transcode.sh input.mp4 output_folder

INPUT="$1"
OUTPUT_DIR="$2"
SEGMENT_TIME=4
FPS=30

if [ -z "$INPUT" ] || [ -z "$OUTPUT_DIR" ]; then
  echo "Usage: $0 <input_video> <output_folder>"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Define output resolutions
declare -A RESOLUTIONS
RESOLUTIONS=( ["480"]="854x480" ["720"]="1280x720" ["1080"]="1920x1080" )

# Define bitrates (you can adjust as needed)
declare -A VIDEO_BITRATES
VIDEO_BITRATES=( ["480"]="800k" ["720"]="2800k" ["1080"]="5000k" )

declare -A AUDIO_BITRATES
AUDIO_BITRATES=( ["480"]="96k" ["720"]="128k" ["1080"]="192k" )

PLAYLISTS=()

for RES in "${!RESOLUTIONS[@]}"; do
  WIDTH_HEIGHT=${RESOLUTIONS[$RES]}
  VBITRATE=${VIDEO_BITRATES[$RES]}
  ABITRATE=${AUDIO_BITRATES[$RES]}
  OUT_PATH="$OUTPUT_DIR/$RES"

  mkdir -p "$OUT_PATH"

  ffmpeg -y -i "$INPUT" \
    -vf "scale=${WIDTH_HEIGHT},fps=$FPS" \
    -c:a aac -b:a "$ABITRATE" \
    -c:v h264 -b:v "$VBITRATE" -profile:v main \
    -hls_time $SEGMENT_TIME \
    -hls_playlist_type vod \
    -hls_segment_filename "$OUT_PATH/seg_%03d.ts" \
    "$OUT_PATH/playlist.m3u8"

  PLAYLISTS+=("#EXT-X-STREAM-INF:BANDWIDTH=$(echo $VBITRATE | sed 's/k//')000,RESOLUTION=${WIDTH_HEIGHT}\n$RES/playlist.m3u8")
done

# Generate master playlist
MASTER="$OUTPUT_DIR/master.m3u8"
echo "#EXTM3U" > "$MASTER"
for PL in "${PLAYLISTS[@]}"; do
  echo -e "$PL" >> "$MASTER"
done

echo "✅ HLS encoding complete."
echo "📂 Master playlist: $MASTER"
