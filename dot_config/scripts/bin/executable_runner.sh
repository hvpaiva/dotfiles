#!/bin/bash

LOG_LEVEL="INFO"

hex_to_rgb() {
  hex_color="$1"
  r=$(printf '%d' "0x${hex_color:1:2}")
  g=$(printf '%d' "0x${hex_color:3:2}")
  b=$(printf '%d' "0x${hex_color:5:2}")
  printf "\x1b[38;2;%d;%d;%dm" "$r" "$g" "$b"
}

show_help() {
  echo "Usage: runner [options]"
  echo ""
  echo "Options:"
  echo "  -l, --level     Specify the log level (default: INFO)"
  echo "  -h, --help      Show this help message"
}

BLUE=$(hex_to_rgb "#82aaff")
PURPLE=$(hex_to_rgb "#c099ff")
GREEN=$(hex_to_rgb "#c3e88d")
CYAN=$(hex_to_rgb "#86e1fc")
YELLOW=$(hex_to_rgb "#ffc777")
RED=$(hex_to_rgb "#ff757f")
GRAY=$(hex_to_rgb "#444a73")
RESET="\x1b[0m"

while [[ "$#" -gt 0 ]]; do
  case $1 in
  -l | --level)
    LOG_LEVEL="$2"
    shift
    ;;
  -h | --help)
    show_help
    exit 0
    ;;
  *)
    echo "Unknown option: $1"
    show_help
    exit 1
    ;;
  esac
  shift
done

export SPRING_PROFILES_ACTIVE=local

APPLICATION=$(basename "$PWD")
export APPLICATION

gradle bootJar && java -Dspring.profiles.active=local -Dspring.output.ansi.enabled=always -Dlogging.level.root=${LOG_LEVEL} -jar build/libs/*.jar |
  sed -E \
    -e "s/([0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3})/${BLUE}&${RESET}/" \
    -e "s/\[([^\]]+)\]/${CYAN}&${RESET}/" \
    -e "s/(INFO)/${GREEN}&${RESET}/" \
    -e "s/(DEBUG)/${PURPLE}&${RESET}/" \
    -e "s/(WARN)/${YELLOW}&${RESET}/" \
    -e "s/(ERROR)/${RED}&${RESET}/" \
    -e "s/([^-]+) -/${GRAY}&${RESET}/" \
    -e "s/(ERROR - .*)/${RED}&${RESET}/"
