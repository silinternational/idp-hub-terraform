#!/usr/bin/env bash

set -euo pipefail

# Base64-encode the pem file
ca_base64=$(curl -fsSL "$1" | base64 --wrap=0)

# Return as JSON
jq -n --arg ca_base64 "$ca_base64" '{"ca_base64": $ca_base64}'
