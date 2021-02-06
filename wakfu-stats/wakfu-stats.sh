#!/bin/bash
###########################################
# wakfu-stats.sh
#
# read relevant information from the games
# log to be handled as you like
###########################################

###########################################
# Defaults
###########################################
DEBUG=false
# logfile to read
LOGFILE=~/.config/zaap/wakfu/logs/wakfu.log
[[ "$OSTYPE" == "darwin"* ]] && LOGFILE=~/Library/Logs/zaap/wakfu/logs/wakfu.log
# color definitions for output highlighting
COLOR_GREEN=$(tput setaf 2)
COLOR_RED=$(tput setaf 1)
COLOR_MAGENTA=$(tput setaf 5)
NO_COLOR=$(tput sgr0)

###########################################
# Functions
###########################################
echo_green()   { echo -e "${COLOR_GREEN}${1}${NO_COLOR}${2}"; }
echo_red()     { echo -e "${COLOR_RED}${1}${NO_COLOR}${2}"; }
echo_magenta() { echo -e "${COLOR_MAGENTA}${1}${NO_COLOR}${2}"; }
exit_hook() { debug "\rSKRIPT ENDED..." >&2; }; trap exit_hook INT TERM
debug() { [[ ${DEBUG} = true ]] && echo -e "DEBUG: ${1}"; }

###########################################
# MAIN LOOP
###########################################
debug "SKRIPT START..."
while getopts "hdf:" opt; do
  case ${opt} in
    h )
      echo "Usage:"
      echo "  $0 -h           Display this help message"
      echo "  $0 -d           Display debug output"
      echo "  $0 -f [FILE]    Use [FILE] instead of default ${LOGFILE}"
      exit 0
      ;;
    d ) 
      DEBUG=true
      ;;
    f ) 
      LOGFILE=$OPTARG
      if [[ ! -f ${LOGFILE} ]]
      then
        echo_red "FATAL: " "Can't open ${LOGFILE} for reading!"
        exit 1
      fi
      ;;
    \? )
      echo "Invalid Option: -$OPTARG" 1>&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

debug "file=${LOGFILE}"

# Get list of resources from Wakfu API!?

tail -F ${LOGFILE} | while read line
do
  # Only handle INFO lines
  if [[ ${line} =~ ^INFO[[:blank:]].*$   ]]
  then
    # Parse the INFO line
    TIME=$(echo ${line}|sed -n 's/^.*\([0-2][0-9]:[0-5][0-9]:[0-5][0-9]\).*$/\1/p')
    TYPE=$(echo ${line}|sed -n 's/^.*\[\(.*\)\].*\[\(.*\)\].*$/\2/p')
    TEXT=$(echo ${line}|sed -n 's/^.*\][[:blank:]]\(.*\)$/\1/p')

    # Output guild messages
    [[ ${TYPE} = Guild ]] && echo_magenta "${TEXT}"

    # Handle Game Log messages
    if [[ ${TYPE} = Game[[:blank:]]Log   ]]
    then
      debug "type='${TYPE}', text='${TEXT}'"

      # You sold 1 item for a total price of 374§ during your absence.
      [[ ${TEXT} =~ ^You[[:blank:]]sold.*$ ]] && echo_green "${TEXT}" \
                                              #; notify-send "[SOLD]" "$line"

      # Miner: +87 XP points. Next level in: 9,104.              => repeats till next level, time? till next level
      # Miner: +103 XP points. +1 level. Next level in: 19,411.

      # You have picked up 4x Mercury.                           => calc avg session day for resource
      # You have picked up 4x Chrome-Plated Mercury.

      # You've earned 100 kamas.
      [[ ${TEXT} =~ ^You\'ve[[:blank:]]earned[[:blank:]].*$ ]] && echo_green "${TEXT}"

      # Xxxxxx (xxxxxx#1025) has just left our world.            => Proximity alert
      # Xxxxxx (xxxxxx#1025) has joined our world.
    fi

  fi
  
done < "${1:-/dev/stdin}"