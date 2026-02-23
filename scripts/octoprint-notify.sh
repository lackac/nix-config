#!/usr/bin/env bash
# OctoPrint event notification script.
# Uploads snapshots/timelapses to Garage S3 and posts to Mattermost.
#
# Usage: octoprint-notify <event> [args...]
#
# Expected environment:
#   WEBHOOK_URL_FILE    - path to file containing Mattermost webhook URL
#   AWS_SHARED_CREDENTIALS_FILE - path to AWS credentials for Garage S3
#   OCTOPRINT_CONFIG    - path to OctoPrint config.yaml (for API key)
#
# All other settings are configured below.

set -euo pipefail

# --- Configuration ---

S3_ENDPOINT="${S3_ENDPOINT:-https://s3.lackac.hu}"
S3_BUCKET="${S3_BUCKET:-octoprint}"
PUBLIC_BASE_URL="${PUBLIC_BASE_URL:-https://octoprint.s3.lackac.hu}"
SNAPSHOT_URL="${SNAPSHOT_URL:-http://127.0.0.1:1984/api/frame.jpeg?src=printer}"
OCTOPRINT_URL="${OCTOPRINT_URL:-http://127.0.0.1:5000}"
OCTOPRINT_CONFIG="${OCTOPRINT_CONFIG:-/var/lib/octoprint/config.yaml}"
BOT_USERNAME="${BOT_USERNAME:-PrusaMK3S}"
BOT_ICON_EMOJI="${BOT_ICON_EMOJI:-3dprinter}"

WEBHOOK_URL="$(cat "${WEBHOOK_URL_FILE:?WEBHOOK_URL_FILE not set}")"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

# Read OctoPrint API key from config
API_KEY=""
if [ -f "$OCTOPRINT_CONFIG" ]; then
  API_KEY="$(yq '.api.key // ""' "$OCTOPRINT_CONFIG")"
fi

# --- Helper functions ---

post_to_mattermost() {
  local text="$1"
  local payload
  payload=$(jq -n \
    --arg text "$text" \
    --arg username "$BOT_USERNAME" \
    --arg icon_emoji "$BOT_ICON_EMOJI" \
    '{text: $text, username: $username, icon_emoji: $icon_emoji}')
  curl -s -o /dev/null -X POST -H 'Content-Type: application/json' \
    -d "$payload" "$WEBHOOK_URL"
}

upload_snapshot() {
  local key="snapshots/${TIMESTAMP}-$1.jpg"
  local tmpfile
  tmpfile="$(mktemp /tmp/octoprint-snapshot-XXXXXX.jpg)"
  if curl -s -o "$tmpfile" -f "$SNAPSHOT_URL"; then
    aws s3 cp "$tmpfile" "s3://${S3_BUCKET}/${key}" \
      --endpoint-url "$S3_ENDPOINT" --region garage --quiet
    rm -f "$tmpfile"
    echo "${PUBLIC_BASE_URL}/${key}"
  else
    rm -f "$tmpfile"
    echo ""
  fi
}

upload_timelapse() {
  local movie_path="$1"
  local movie_basename="$2"
  local key="timelapses/${movie_basename}"
  aws s3 cp "$movie_path" "s3://${S3_BUCKET}/${key}" \
    --endpoint-url "$S3_ENDPOINT" --region garage --quiet
  echo "${PUBLIC_BASE_URL}/${key}"
}

format_duration() {
  local seconds="${1%%.*}"
  local hours=$((seconds / 3600))
  local minutes=$(( (seconds % 3600) / 60 ))
  if [ "$hours" -gt 0 ]; then
    echo "${hours}h ${minutes}m"
  else
    echo "${minutes}m"
  fi
}

format_size() {
  local bytes="$1"
  if [ "$bytes" -ge 1048576 ]; then
    echo "$(( bytes / 1048576 )).$(( (bytes % 1048576) * 10 / 1048576 ))MB"
  elif [ "$bytes" -ge 1024 ]; then
    echo "$(( bytes / 1024 ))KB"
  else
    echo "${bytes}B"
  fi
}

# Query OctoPrint REST API (returns empty string on failure)
octoprint_api() {
  local endpoint="$1"
  if [ -n "$API_KEY" ]; then
    curl -s -f -H "X-Api-Key: $API_KEY" "${OCTOPRINT_URL}/api/${endpoint}" 2>/dev/null || echo ""
  else
    echo ""
  fi
}

# Format printer temps: "Bed: 60.0/60.0, Nozzle: 215.0/215.0"
get_temps() {
  local printer_json
  printer_json="$(octoprint_api "printer")"
  if [ -n "$printer_json" ]; then
    echo "$printer_json" | jq -r '
      [
        (if .temperature.bed then
          "Bed: \(.temperature.bed.actual // 0 | . * 10 | round / 10)/\(.temperature.bed.target // 0 | . * 10 | round / 10)"
        else empty end),
        (if .temperature.tool0 then
          "Nozzle: \(.temperature.tool0.actual // 0 | . * 10 | round / 10)/\(.temperature.tool0.target // 0 | . * 10 | round / 10)"
        else empty end)
      ] | join(", ")
    ' 2>/dev/null || echo ""
  else
    echo ""
  fi
}

get_job_info() {
  octoprint_api "job"
}

# Read Raspberry Pi SoC temperature
get_soc_temp() {
  if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    local millideg
    millideg="$(cat /sys/class/thermal/thermal_zone0/temp)"
    echo "$(( millideg / 1000 )).$(( (millideg % 1000) / 100 ))"
  else
    echo ""
  fi
}

# Build a one-line status: "Bed: 60/60, Nozzle: 215/215, RasPi: 45.2°C"
build_status_line() {
  local parts=()
  local temps
  temps="$(get_temps)"
  [ -n "$temps" ] && parts+=("$temps")
  local soc
  soc="$(get_soc_temp)"
  [ -n "$soc" ] && parts+=("RasPi: ${soc}°C")
  if [ ${#parts[@]} -gt 0 ]; then
    local IFS=", "
    echo "${parts[*]}"
  else
    echo ""
  fi
}

# Extract a field from job JSON, empty string if missing
job_field() {
  local json="$1" path="$2"
  echo "$json" | jq -r "$path // empty" 2>/dev/null || echo ""
}

# --- Main ---

EVENT="$1"
shift

case "$EVENT" in
  PrintStarted)
    NAME="$1"
    SNAP_URL="$(upload_snapshot "start")"

    JOB_JSON="$(get_job_info)"
    EST_TIME="" ETA="" FILE_SIZE=""
    if [ -n "$JOB_JSON" ]; then
      EST_SECS="$(job_field "$JOB_JSON" '.job.estimatedPrintTime')"
      if [ -n "$EST_SECS" ]; then
        EST_TIME="$(format_duration "$EST_SECS")"
        ETA="$(date -d "+${EST_SECS%%.*} seconds" +%H:%M 2>/dev/null || true)"
      fi
      SIZE_BYTES="$(job_field "$JOB_JSON" '.job.file.size')"
      [ -n "$SIZE_BYTES" ] && FILE_SIZE="$(format_size "$SIZE_BYTES")"
    fi

    MSG=":rocket: **Print started:** ${NAME}"
    [ -n "$FILE_SIZE" ] && MSG="${MSG} (${FILE_SIZE})"
    [ -n "$EST_TIME" ] && MSG="${MSG}"$'\n'"**Estimated print time:** ${EST_TIME}"
    [ -n "$ETA" ] && MSG="${MSG} | **ETA:** ${ETA}"

    STATUS="$(build_status_line)"
    [ -n "$STATUS" ] && MSG="${MSG}"$'\n'"${STATUS}"
    [ -n "$SNAP_URL" ] && MSG="${MSG}"$'\n'"![](${SNAP_URL})"
    post_to_mattermost "$MSG"
    ;;

  PrintDone)
    NAME="$1"
    PRINT_TIME="$2"
    TIME_STR="$(format_duration "$PRINT_TIME")"
    SNAP_URL="$(upload_snapshot "done")"

    JOB_JSON="$(get_job_info)"
    EST_TIME="" FILE_SIZE=""
    if [ -n "$JOB_JSON" ]; then
      EST_SECS="$(job_field "$JOB_JSON" '.job.estimatedPrintTime')"
      [ -n "$EST_SECS" ] && EST_TIME="$(format_duration "$EST_SECS")"
      SIZE_BYTES="$(job_field "$JOB_JSON" '.job.file.size')"
      [ -n "$SIZE_BYTES" ] && FILE_SIZE="$(format_size "$SIZE_BYTES")"
    fi

    MSG=":tada: **Print finished:** ${NAME}"
    [ -n "$FILE_SIZE" ] && MSG="${MSG} (${FILE_SIZE})"
    MSG="${MSG}"$'\n'"**Print time:** ${TIME_STR}"
    [ -n "$EST_TIME" ] && MSG="${MSG} (estimated: ${EST_TIME})"

    STATUS="$(build_status_line)"
    [ -n "$STATUS" ] && MSG="${MSG}"$'\n'"${STATUS}"
    [ -n "$SNAP_URL" ] && MSG="${MSG}"$'\n'"![](${SNAP_URL})"
    post_to_mattermost "$MSG"
    ;;

  PrintFailed)
    NAME="$1"
    REASON="$2"
    SNAP_URL="$(upload_snapshot "failed")"

    JOB_JSON="$(get_job_info)"
    FILE_SIZE=""
    if [ -n "$JOB_JSON" ]; then
      SIZE_BYTES="$(job_field "$JOB_JSON" '.job.file.size')"
      [ -n "$SIZE_BYTES" ] && FILE_SIZE="$(format_size "$SIZE_BYTES")"
    fi

    MSG=":fire: **Print failed:** ${NAME}"
    [ -n "$FILE_SIZE" ] && MSG="${MSG} (${FILE_SIZE})"
    MSG="${MSG}"$'\n'"**Reason:** ${REASON}"

    STATUS="$(build_status_line)"
    [ -n "$STATUS" ] && MSG="${MSG}"$'\n'"${STATUS}"
    [ -n "$SNAP_URL" ] && MSG="${MSG}"$'\n'"![](${SNAP_URL})"
    post_to_mattermost "$MSG"
    ;;

  MovieDone)
    MOVIE_PATH="$1"
    MOVIE_BASENAME="$2"
    GCODE_NAME="$3"
    TIMELAPSE_URL="$(upload_timelapse "$MOVIE_PATH" "$MOVIE_BASENAME")"
    MSG=":movie_camera: **Timelapse ready:** [${MOVIE_BASENAME}](${TIMELAPSE_URL})"
    [ -n "$GCODE_NAME" ] && MSG="${MSG} (from ${GCODE_NAME})"
    post_to_mattermost "$MSG"
    ;;

  *)
    echo "Unknown event: $EVENT" >&2
    exit 1
    ;;
esac
