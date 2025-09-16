#!/bin/sh
OPENWEB_API_KEY="${OPENWEB_API_KEY}"

curl -X POST http://${public_ip}:8443/api/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENWEB_API_KEY" \
  -d '{
    "model": "foundation-sec-8b-instruct:latest",
    "messages": [
      {
        "role": "user",
	"content": "Explain Cisco firewalls in simple terms"
      }
    ]
  }' | jq
