# Valheim-сервер на EC2. Значения задаются в ~/.zshrc.local (вне репозитория):
#   export VALHEIM_INSTANCE_ID=i-...
#   export VALHEIM_HOST=...            # DNS-имя сервера
# Необязательные (по умолчанию ap-south-1 / valheim):
#   export VALHEIM_REGION=...  VALHEIM_PROFILE=...

_valheim_id() { print -r -- "${VALHEIM_INSTANCE_ID:?не задан VALHEIM_INSTANCE_ID (см. ~/.zshrc.local)}"; }

# aws с регионом и профилем сервера
_valheim_aws() {
  aws "$@" --region "${VALHEIM_REGION:-ap-south-1}" --profile "${VALHEIM_PROFILE:-valheim}"
}

valheim-start() {
  local id; id="$(_valheim_id)" || return 1
  _valheim_aws ec2 start-instances --instance-ids "$id" --output table
}

valheim-stop() {
  local id; id="$(_valheim_id)" || return 1
  _valheim_aws ec2 stop-instances --instance-ids "$id" --output table
}

valheim-status() {
  local id; id="$(_valheim_id)" || return 1
  _valheim_aws ec2 describe-instances --instance-ids "$id" \
    --query 'Reservations[0].Instances[0].[State.Name,PublicIpAddress]' \
    --output table
}

valheim() {
  local id host
  id="$(_valheim_id)" || return 1
  host="${VALHEIM_HOST:?не задан VALHEIM_HOST (см. ~/.zshrc.local)}"

  local STATE
  STATE=$(_valheim_aws ec2 describe-instances \
    --instance-ids "$id" \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text)

  echo "EC2 state: $STATE"

  if [[ "$STATE" == "stopped" ]]; then
    echo "Starting Valheim server..."
    _valheim_aws ec2 start-instances --instance-ids "$id" --output text >/dev/null
  elif [[ "$STATE" == "stopping" ]]; then
    echo "Server is still stopping. Wait a bit and run 'valheim' again."
    return 1
  elif [[ "$STATE" != "running" && "$STATE" != "pending" ]]; then
    echo "Unexpected EC2 state: $STATE"
    return 1
  else
    echo "Server is already starting or running."
  fi

  echo "Waiting for EC2 to become running..."
  _valheim_aws ec2 wait instance-running --instance-ids "$id"

  echo "EC2 is running."
  echo "Waiting for Valheim to boot..."

  for i in {1..24}; do
    if nc -z -u -w 1 "$host" 2456 >/dev/null 2>&1; then
      echo
      echo "Valheim should be ready:"
      echo "$host:2456"
      return 0
    fi

    printf "."
    sleep 5
  done

  echo
  echo "EC2 is running, but Valheim readiness could not be confirmed."
  echo "Try connecting anyway:"
  echo "$host:2456"
}

valheim-ssh() {
  local id; id="$(_valheim_id)" || return 1
  _valheim_aws ssm start-session --target "$id"
}

valheim-logs() {
  local id; id="$(_valheim_id)" || return 1
  _valheim_aws ssm start-session \
    --target "$id" \
    --document-name AWS-StartInteractiveCommand \
    --parameters 'command=["sudo journalctl -u valheim -f"]'
}
