#!/bin/sh
FOUNDATION_API_KEY="${FOUNDATION_API_KEY}"

curl -X POST http://${public_ip}:9443/generate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $FOUNDATION_API_KEY" \
  -d '{
    "prompt": "Explain Cisco firewalls in simple terms",
    "max_new_tokens": 150
  }'

