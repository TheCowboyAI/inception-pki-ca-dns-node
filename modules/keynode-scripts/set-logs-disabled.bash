function eventlog {
  local evt="$1"
  echo "$evt" >> "$EVENTLOG"
}

attrevt=$( jq -n \
  --arg disable_log "Logging has been manually disabled !!!" \
  '{"YubikeyAttributesSet":{"disable_log":$disable_log}}'
)

eventlog "$attrevt"

export LOGFILE=/dev/null
export EVENTLOG=/dev/null
