#! /bin/sh

set -e # exit on error
. "$(dirname "$0")/helpers.sh" # import helpers

verbose=0
debug=0

# Check DEBUG environment variable
if isTruthy "$DEBUG"; then
  debug=1
fi

# Parse command line arguments
while [ "$#" -gt 0 ]; do
  case "$1" in
    -d|--debug)
      # If there is an argument provided for the flag
      # and it doesn't start with "-" (which would actually be another flag)
      if [ "$#" -gt 1 ] && [ "${2#-}" = "$2" ]; then
        # -d with an argument
        if isFalsey "$2"; then
          debug=0
        elif isTruthy "$2"; then
          debug=1
        else
          echo "Error: Cannot process $1 \"$2\" as a boolean" >&2
          exit 1
        fi
        shift
      else
        # -d with no argument means enable debug
        debug=1
      fi
      ;;
    -d=*|--debug=*)
      # Extract value after =
      debug_val="${1#*=}"
      if isTruthy "$debug_val"; then
        debug=1
      elif isFalsey "$debug_val"; then
        debug=0
      else
        echo "Error: Cannot process --debug=$debug_val as a boolean" >&2
        exit 1
      fi
      ;;
    -v|--verbose)
      verbose=1
      ;;
    -q|--quiet)
      verbose=0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      echo "Usage: $0 [-d|--debug [true|false]] [-v|--verbose] [-q|--quiet]" >&2
      exit 1
      ;;
  esac
  shift
done

# Start the appropriate binary
if [ $debug -eq 1 ]; then
  # Run debugger and debug build
  if [ $verbose -eq 1 ]; then
    echo "Starting in DEBUG mode"
    echo "Debug port: ${DEBUG_PORT}"
  fi
  exec "${DEBUG_SCRIPT}"
else
  # Run production build
  if [ $verbose -eq 1 ]; then
    echo "Starting in PRODUCTION mode"
  fi
  exec "${APP_BIN}"
fi
