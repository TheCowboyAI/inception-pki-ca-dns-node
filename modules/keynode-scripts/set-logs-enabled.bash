function eventlog {
  local evt="$1"
  echo "$evt" >> "$EVENTLOG"
}

export LOGFILE="./yubikey_setup_$(date +%F).log"
export EVENTLOG="./yubikey_setup_$(date +%F).events.json"

attrevt=$( jq -n \
  --arg enable_log "Logging has been enabled !!!" \
  '{"YubikeyAttributesSet":{"enable_log":$enable_log}}'
)

eventlog "$attrevt"
