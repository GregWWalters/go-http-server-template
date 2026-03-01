# POSIX-compliant shell script - avoid bash-specific features
DEBUG_PORT=${DEBUG_PORT:=2345}
BIN_DIR=${BIN_DIR:=$(dirname "$0")}
SCRIPT_DIR=${SCRIPT_DIR:=$BIN_DIR}
APP_NAME=${APP_NAME:=app}
# POSIX-compliant parameter expansion for removing suffix
DEBUG_NAME=${DEBUG_NAME:=${APP_NAME%-api}-debug}
APP_BIN="${APP_BIN:=${BIN_DIR}/${APP_NAME}}"
DEBUG_BIN="${DEBUG_BIN:=${BIN_DIR}/${DEBUG_NAME}}"
DLV_BIN="${DLV_BIN:=$BIN_DIR/dlv}"
DEBUG_SCRIPT="${DEBUG_SCRIPT:=${SCRIPT_DIR}/debug.sh}"

export DEBUG_PORT BIN_DIR SCRIPT_DIR APP_NAME DEBUG_NAME
export APP_BIN DEBUG_BIN DLV_BIN DEBUG_SCRIPT

# Check if a value represents "true"
isTruthy() {
  val=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  case $val in
  t | true) return 0 ;;
  y | yes) return 0 ;;
  on) return 0;;
  1) return 0;;
  *) return 1;;
  esac
}

# Check if a value represents "false"
isFalsey() {
  val=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  case $val in
  f | false) return 0 ;;
  n | no) return 0 ;;
  off) return 0;;
  0) return 0;;
  *) return 1;;
  esac
}
