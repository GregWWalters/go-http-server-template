#! /bin/sh
set -e
. "$(dirname "$0")/helpers.sh"

SIGNAL=INT

quitEach() {
  for PID in "$@"; do
    while 1> /dev/null 2>&1 kill -0 $PID; do
      kill -s $SIGNAL "$PID"
      sleep 0.1
    done
  done
  return $?
}

PIDs=""
trap 'quitEach $PIDs' HUP INT QUIT TERM

# Start the debug binary
${DEBUG_BIN} &
APP_PID=$!
echo "Started debug binary with PID: $APP_PID"

# Give the app a moment to start before attaching debugger
sleep 0.5

# Attach delve to the running process
${DLV_BIN} attach $APP_PID \
  --listen=:"${DEBUG_PORT}" \
  --headless=true \
  --api-version=2 \
  --accept-multiclient \
  --continue &
DLV_PID=$!
echo "Started delve debugger with PID: $DLV_PID"

# Track both processes for cleanup
PIDs="$APP_PID $DLV_PID"
wait
