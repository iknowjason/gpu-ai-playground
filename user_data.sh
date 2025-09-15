#!/bin/bash
set -e
echo "Start bootstrap script"

N8N_DOMAIN="${N8N_DOMAIN:-}"
ACME_EMAIL="${ACME_EMAIL:-}"  

# 1. System Preparation
echo "System preparation"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y net-tools jq
apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# 2. Install Core Dependencies
echo "Install core dependencies"
apt-get install -y docker.io docker-compose-v2 git

# 3. Install NVIDIA Drivers & Toolkit
echo "Install Nvidia PPA"
# This is the most critical part for GPU access.
# Add NVIDIA package repositories
apt-get install -y software-properties-common
add-apt-repository ppa:graphics-drivers/ppa -y
apt-get update -y

# Install NVIDIA drivers (version 535). Choose a version compatible with your instance/CUDA needs.
echo "Install Nvidia drivers"
apt-get install -y nvidia-driver-535

# Install NVIDIA Container Toolkit
echo "Install Nvidia Container Toolkit"
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt-get update -y
apt-get install -y nvidia-container-toolkit

# 4. Configure and Restart Docker 
# Configure Docker to use the NVIDIA runtime
echo "Configure Docker to use the Nvidia runtime"
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

# Add ubuntu user to the docker group to run docker commands without sudo
usermod -aG docker ubuntu

# 5. Install Caddy (HTTPS reverse proxy)
echo "Install Caddy"
apt-get install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt-get update -y
apt-get install -y caddy


# 5. Deploy the n8n AI Kit
echo "Deploy the n8n AI Kit"

cd /home/ubuntu
echo "Git clone the n8n AI Kit"
git clone https://github.com/iknowjason/self-hosted-ai-starter-kit.git
cd self-hosted-ai-starter-kit

echo "Fetching public IP from AWS IMDSv2"
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
IP_ADDRESS=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
PUBLIC_DNS=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-hostname || true)
echo "Successfully retrieved public IP: $IP_ADDRESS"

# Decide the external host for URLs/Caddy
if [ -n "$N8N_DOMAIN" ]; then
  EXTERNAL_HOST="$N8N_DOMAIN"
else
  EXTERNAL_HOST="${PUBLIC_DNS:-$PUBLIC_IP}"
fi
echo "External host for n8n URLs: $EXTERNAL_HOST"

echo "Configuring .env for HTTPS behind Caddy"
cat >.env << EOF
POSTGRES_DB=n8n
POSTGRES_USER=n8n
POSTGRES_PASSWORD=$(openssl rand -base64 32)

N8N_HOST=${EXTERNAL_HOST}
N8N_PORT=5678
N8N_PROTOCOL=https
N8N_SECURE_COOKIE=true
N8N_EDITOR_BASE_URL=https://${EXTERNAL_HOST}/
WEBHOOK_URL=https://${EXTERNAL_HOST}/
N8N_TRUSTED_PROXIES=loopback

N8N_ENCRYPTION_KEY=$(openssl rand -base64 32)
GENERIC_TIMEZONE=America/New_York
DB_TYPE=postgresdb
DB_POSTGRESDB_DATABASE=\${POSTGRES_DB}
DB_POSTGRESDB_HOST=db
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_USER=\${POSTGRES_USER}
DB_POSTGRESDB_PASSWORD=\${POSTGRES_PASSWORD}

OLLAMA_HOST=http://ollama:11434
EOF

# Launch the services using the NVIDIA GPU profile in detached mode
echo "Launch docker compose with gpu-nvidia up"
docker compose --profile gpu-nvidia up -d

# 9. Configure Caddy reverse proxy to localhost:5678 for n8n HTTPS 
echo "Writing Caddyfile for $EXTERNAL_HOST"
if [ -n "$N8N_DOMAIN" ]; then
  cat > /etc/caddy/Caddyfile <<EOCADDY
{
  $( [ -n "$ACME_EMAIL" ] && echo "email $ACME_EMAIL" )
}
$N8N_DOMAIN {
  encode zstd gzip
  reverse_proxy 127.0.0.1:5678
}

:80 {
  redir https://$N8N_DOMAIN{uri}
}
EOCADDY

else
  HOST_FALLBACK="$EXTERNAL_HOST"
  cat > /etc/caddy/Caddyfile <<EOCADDY

# n8n on 443
$HOST_FALLBACK {
  tls internal
  encode zstd gzip
  reverse_proxy 127.0.0.1:5678
}

# Open WebUI on 8443
:8443 {
  encode zstd gzip
  reverse_proxy 127.0.0.1:8080 {
  }
}

# Native PyTorch model API on 9443
:9443 {
    encode zstd gzip
    reverse_proxy 127.0.0.1:9000 {
    }
}

:80 {
  redir https://$HOST_FALLBACK{uri}
}
EOCADDY
fi

# Reload and Enable Caddy
echo "Reload Caddy"
systemctl enable caddy
systemctl reload caddy || systemctl restart caddy

# Install Hugging Face CLI and Download Cisco Foundation Model
echo "Installing Hugging Face CLI and dependencies"
apt-get install -y python3-pip
pip3 install --upgrade pip
pip3 install huggingface-hub

# Create directory for models
echo "Create models directory"
mkdir -p /models
cd /models

echo "Downloading Cisco Foundation AI Model (Foundation-Sec-8B-Instruct)"
hf download Mungert/Foundation-Sec-8B-Instruct-GGUF \
  --local-dir /models/Foundation-Sec-8B-Instruct-GGUF \
  --include "*f16*.gguf"

# Create the Ollama Modelfile for Foundation-Sec-8B-Instruct
cat >/models/Foundation-Sec-8B-Instruct-GGUF/Modelfile <<'EOF'
FROM Foundation-Sec-8B-Instruct-f16_q8_0.gguf 
TEMPLATE """{{ .System }}
{{ .Prompt }}"""
PARAMETER temperature 0.7
PARAMETER stop "<|eot_id|>"
EOF

# Preload Cisco model into Ollama container
echo "Waiting for ollama container to be healthy"
# Sleep 30 for container to be healthy first
sleep 30
echo "Preload the foundation-sec-8b container into ollama"
docker exec -w /models/Foundation-Sec-8B-Instruct-GGUF ollama \
  ollama create foundation-sec-8b -f Modelfile

# Install FastAPI native inference server with Authorization Checks 
echo "Setting up FastAPI server for Cisco Foundation model"

mkdir -p /home/ubuntu/foundation_server
cd /home/ubuntu/foundation_server

# Generate a random API key for this instance
FOUNDATION_API_KEY=$(openssl rand -hex 32)
echo "FOUNDATION_API_KEY=$FOUNDATION_API_KEY" | tee /home/ubuntu/foundation_server/.env

# Python venv + dependencies
apt-get install -y python3-venv
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install fastapi uvicorn transformers accelerate torch
deactivate

# Get the PyTorch inference FastAPI server.py
wget https://raw.githubusercontent.com/iknowjason/self-hosted-ai-starter-kit/refs/heads/main/server.py

# systemd service for persistent API server
cat >/etc/systemd/system/foundation.service <<'EOF'
[Unit]
Description=Cisco Foundation 8B Inference Server
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/foundation_server
EnvironmentFile=/home/ubuntu/foundation_server/.env
ExecStart=/home/ubuntu/foundation_server/venv/bin/uvicorn server:app --host 0.0.0.0 --port 9000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "Installing service"
systemctl enable foundation
systemctl start foundation

# Create local inference test scripts
echo "Creating local inference test scripts"

mkdir -p /home/ubuntu/test_inference_scripts
chown ubuntu:ubuntu /home/ubuntu/test_inference_scripts

# 1. Ollama local inference (Cisco Foundation model)
echo "Creating ollama test script"
cat >/home/ubuntu/test_inference_scripts/ollama_test.sh <<'EOF'
#!/bin/sh
curl -s http://127.0.0.1:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "foundation-sec-8b",
    "prompt": "Explain Cisco firewalls in simple terms",
    "stream": false
  }' | jq .
EOF
chmod +x /home/ubuntu/test_inference_scripts/ollama_test.sh

# 2. Open WebUI local inference (port 8080, requires API key)
echo "Creating Open WebUI test script"
cat >/home/ubuntu/test_inference_scripts/openwebui_test.sh <<'EOF'
#!/bin/sh
OPENWEB_API_KEY="CHANGE_BEFORE_FIRST_USE"

curl -X POST http://127.0.0.1:8080/api/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENWEB_API_KEY" \
  -d '{
    "model": "foundation-sec-8b:latest",
    "messages": [
      {
        "role": "user",
	"content": "Explain Cisco firewalls in simple terms"
      }
    ]
  }' | jq .
EOF
chmod +x /home/ubuntu/test_inference_scripts/openwebui_test.sh

# 3. PyTorch native inference API (port 9000, auto-loads API key)
echo "Creating PyTorch native test script for Foundation Model"
cat >/home/ubuntu/test_inference_scripts/pytorch_test.sh <<'EOF'
#!/bin/sh
PYTORCH_API_KEY=$(grep FOUNDATION_API_KEY /home/ubuntu/foundation_server/.env | cut -d= -f2)

curl -s http://127.0.0.1:9000/generate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $PYTORCH_API_KEY" \
  -d '{
    "prompt": "Explain Cisco firewalls in simple terms",
    "max_new_tokens": 150
  }' | jq .
EOF
chmod +x /home/ubuntu/test_inference_scripts/pytorch_test.sh

echo "End of bootstrap script"
