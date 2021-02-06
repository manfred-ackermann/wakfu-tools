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
if [ -z $TERM ]
then
  COLOR_GREEN=$(tput setaf 2)
  COLOR_RED=$(tput setaf 1)
  COLOR_MAGENTA=$(tput setaf 5)
  NO_COLOR=$(tput sgr0)
fi

###########################################
# Functions
###########################################
stats() {
  for key in "${!HARVEST_NAME[@]}"
  do
    if [[ ${key} -ne 0 ]]
    then
      echo "nme: ${HARVEST_NAME[${key}]}, cnt: ${HARVEST_COUNT[${key}]}, sum: ${HARVEST_AMOUNT[${key}]}"
    fi
  done
}

echo_green()   { echo -e "${COLOR_GREEN}${1}${NO_COLOR}${2}"; }
echo_red()     { echo -e "${COLOR_RED}${1}${NO_COLOR}${2}"; }
echo_magenta() { echo -e "${COLOR_MAGENTA}${1}${NO_COLOR}${2}"; }
debug() { [[ ${DEBUG} = true ]] && echo -e "DEBUG: ${1}"; }
exit_hook() {  echo_red "\rSKRIPT ENDED..." >&2; }; trap exit_hook INT TERM

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
    g ) 
      if [ -x $(which curl) -a -x $(which jq) ]
      then
        debug "curl and jq found."
      else
        echo_red "ERROR: " "Requirements for Ankama Wakfu-GameDB usage not fulfilled."
        echo_red "       " "Ensure curl and jq are installed and executable!"
        exit 1
      fi
      ;;
    \? )
      echo_red "Invalid Option: " "-$OPTARG"
      #echo "Invalid Option: -$OPTARG" 1>&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

debug "file=${LOGFILE}"

# Get list of resources from Wakfu API!?
GAMEDB_DIR=~/.wakfu-stats
mkdir -p ${GAMEDB_DIR}
debug "$(ls -l ${GAMEDB_DIR}/jobsItems)"
GAMEDB_VERSION=$(curl --silent --fail "https://wakfu.cdn.ankama.com/gamedata/config.json"|jq -r .version)
curl --silent --fail --output ${GAMEDB_DIR}/jobsItems --time-cond ${GAMEDB_DIR}/jobsItems \
      https://wakfu.cdn.ankama.com/gamedata/${GAMEDB_VERSION}/jobsItems.json
debug "$(ls -l ${GAMEDB_DIR}/jobsItems)"

tail -n 0 -F ${LOGFILE} | while read line
do
  # Only handle INFO lines
  if [[ ${line} =~ ^INFO[[:blank:]].*$   ]]
  then
    # Parse the INFO line
    TIME=$( echo ${line} | sed -n 's/^.*\([0-2][0-9]:[0-5][0-9]:[0-5][0-9]\).*$/\1/p' )
    TYPE=$( echo ${line} | sed -n 's/^.*\[\(.*\)\].*\[\(.*\)\].*$/\2/p' )
    TEXT=$( echo ${line} | sed -n 's/^.*\][[:blank:]]\(.*\)$/\1/p' )

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
      # Miner: +103 XP points. +1 level. Next level in: wakfu-stats.sh -d -g19,411.

      # You have picked up 4x Mercury.                           => calc avg session day for resource
      # You have picked up 4x Chrome-Plated Mercury.
      declare HARVEST_AMOUNT
      declare HARVEST_COUNT
      declare HARVEST_NAME
      if [[ ${TEXT} =~ ^You[[:blank:]]have[[:blank:]]picked[[:blank:]]up.*$ ]]
      then
        ITEM_NAME=$(  echo ${TEXT} | sed -n 's/^.*up[[:blank:]].*x[[:blank:]]\(.*\)\.$/\1/p')
        ITEM_COUNT=$( echo ${TEXT} | sed -n 's/^.*up[[:blank:]]\(.*\)x[[:blank:]].*$/\1/p')
        
        # Find item id for usage as hash key
        ITEM_ID=$( jq ".[] | select(.title.en==\"${ITEM_NAME}\") | .definition.id" ${GAMEDB_DIR}/jobsItems )

        if [[ ! -z "$ITEM_ID" ]]
        then
          HARVEST_COUNT[${ITEM_ID} ]=$(( ${HARVEST_COUNT[  ${ITEM_ID} ] } + 1 ))
          HARVEST_AMOUNT[${ITEM_ID} ]=$(( ${HARVEST_AMOUNT[ ${ITEM_ID} ] } + ${ITEM_COUNT} ))
          HARVEST_NAME[${ITEM_ID} ]="${ITEM_NAME}"

          echo_green "HARVEST: " "${ITEM_COUNT}x ${ITEM_NAME} (avg: $(( ${HARVEST_AMOUNT[${ITEM_ID}]} / ${HARVEST_COUNT[${ITEM_ID}]} )), harvests: ${HARVEST_COUNT[${ITEM_ID}]}, sum: ${HARVEST_AMOUNT[${ITEM_ID}]})"
        fi
      fi

      # You've earned 100 kamas.
      [[ ${TEXT} =~ ^You\'ve[[:blank:]]earned[[:blank:]].*$ ]] && echo_green "${TEXT}"

      # Xxxxxx (xxxxxx#1025) has just left our world.            => Proximity alert
      # Xxxxxx (xxxxxx#1025) has joined our world.
    fi
  fi
  
done < "${1:-/dev/stdin}"