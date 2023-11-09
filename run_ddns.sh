#!/bin/bash

# Stop the script if any command returns a non-zero exit code 
set -e

# Configuration file
source config.sh

# Function to log messages to the log file with timestamps
log_message() {
  TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
  EVENT="$1"
  MESSAGE="$2"
  echo "$TIMESTAMP,$EVENT,$MESSAGE" >> "$LOG_FILE"
  echo "$TIMESTAMP,$EVENT,$MESSAGE"
}

log_message "STARTED" "GoDaddy DDNS execution started"
SERVER_IP=$(curl -sf https://api.ipify.org) || {
    log_message "FAILED_SERVER_IP_CHECK" "Failed to get server's public IP"
    exit 1
}
log_message "CHECKED_SERVER_IP" "Server's current public IP: $SERVER_IP"

if ! [[ $SERVER_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  log_message "INVALID_SERVER_IP" "Server's reported current public IP is invalid: $SERVER_IP"
  exit 1
fi

for FQDN in "${FQDNS[@]}"; do
  DOMAIN="$(echo "$FQDN" | rev | cut -d. -f1-2 | rev)"
  SUBDOMAIN="$(echo "$FQDN" | cut -d. -f1)"
  DOMAIN_IP=$(curl -s -X GET -H "Authorization: sso-key $GODADDY_SSO" \
    "https://api.godaddy.com/v1/domains/$DOMAIN/records/A/$SUBDOMAIN" | jq -r '.[].data')
  log_message "CHECKED_DOMAIN_IP" "Current GoDaddy IP for $FQDN: $DOMAIN_IP"

  if ! [[ $DOMAIN_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_message "INVALID_DOMAIN_IP" "Domain's reported current public IP is invalid: $DOMAIN_IP"
    continue
  fi

  if [ "$SERVER_IP" != "$DOMAIN_IP" ]; then
    # Send email notification through IFTTT webhook
    curl -s -X POST \
      -H "Content-Type: application/json" \
      -d "{\"message\": \"Updating $FQDN from $DOMAIN_IP to $SERVER_IP...\"}" \
      "https://maker.ifttt.com/trigger/$IFTTT_EVENT/json/with/key/$IFTTT_KEY" > /dev/null
    log_message "INVOKED_IFTTT_WEBHOOK" "Invoked IFTTT webhook to send email notification"
    # Update the A record
    curl -s -X PUT \
      -H "Authorization: sso-key $GODADDY_SSO" \
      -H "Content-Type: application/json" \
      -d "[{\"data\": \"$SERVER_IP\", \"ttl\": 600}]" \
      "https://api.godaddy.com/v1/domains/$DOMAIN/records/A/$SUBDOMAIN"
    log_message "UPDATED_GODADDY" "Updated $FQDN from $DOMAIN_IP to $SERVER_IP..."
  fi
done
log_message "COMPLETED" "GoDaddy DDNS execution complete"
