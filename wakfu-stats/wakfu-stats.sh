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
# color definitions for output highlighting
COLOR_GREEN=$(tput setaf 2)
COLOR_RED=$(tput setaf 1)
NO_COLOR=$(tput sgr0)
###########################################

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
      [[ -f ${LOGFILE} ]] || (echo "${COLOR_RED}FATAL${NO_COLOR}: Can't open ${LOGFILE} for reading!"; exit 1)
      ;;
    \? )
      echo "Invalid Option: -$OPTARG" 1>&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

[[ ${DEBUG} = true ]] && echo "DEBUG: file=${LOGFILE}"

# Get list of resources from Wakfu API!?

tail -n 200 -f ${LOGFILE} | while read line
do
  # Only handle INFO lines
  if [[ ${line} =~ ^INFO[[:blank:]].*$   ]]
  then
    # Parse the INFO line
    TIME=$(echo ${line}|sed -n 's/^.*\([0-2][0-9]:[0-5][0-9]:[0-5][0-9]\).*$/\1/p')
    TYPE=$(echo ${line}|sed -n 's/^.*\[\(.*\)\].*\[\(.*\)\].*$/\2/p')
    TEXT=$(echo ${line}|sed -n 's/^.*\][[:blank:]]\(.*\)$/\1/p')

    # Output guild messages
    [[ ${TYPE} = Guild ]] && echo "${COLOR_RED}[GUILD ]${NO_COLOR} ${TEXT}"

    # Handle Game Log messages
    if [[ ${TYPE} = Game[[:blank:]]Log   ]]
    then
      [[ ${DEBUG} = true ]] && echo "DEBUG: type='${TYPE}', text='${TEXT}'"

      # You sold 1 item for a total price of 374§ during your absence.
      [[ ${TEXT} =~ ^You[[:blank:]]sold.*$ ]] && echo "${COLOR_GREEN}[MARKET]${NO_COLOR} ${TEXT}" \
                                              #; notify-send "[SOLD]" "$line"

      # Miner: +87 XP points. Next level in: 9,104.              => repeats till next level, time? till next level
      # Miner: +103 XP points. +1 level. Next level in: 19,411.

      # You have picked up 4x Mercury.                           => calc avg session day for resource
      # You have picked up 4x Chrome-Plated Mercury.

      # Xxxxxx (xxxxxx#1025) has just left our world.            => Proximity alert
      # Xxxxxx (xxxxxx#1025) has joined our world.
    fi

  fi
  
done < "${1:-/dev/stdin}"