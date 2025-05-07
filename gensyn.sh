#!/usr/bin/env bash
set -euo pipefail

# Update & install base packages
echo "==> Updating APT and installing Python, curl, wget, screen, git, lsof..."
sudo apt update
sudo apt install -y python3 python3-venv python3-pip curl wget screen git lsof

# Install Node.js 20.x
echo "==> Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt update
sudo apt install -y nodejs

# Add Yarn GPG key & repository (with dearmor + fallback)
echo "==> Setting up Yarn keyring and repository..."
sudo mkdir -p /etc/apt/keyrings

if curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg \
     | gpg --dearmor \
     | sudo tee /etc/apt/keyrings/yarn.gpg > /dev/null; then
  echo "Primary keyring import succeeded."
  sudo chmod 644 /etc/apt/keyrings/yarn.gpg
  echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" \
    | sudo tee /etc/apt/sources.list.d/yarn.list
else
  echo "Primary import failed – falling back to legacy apt-key method."
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
  echo "deb https://dl.yarnpkg.com/debian/ stable main" \
    | sudo tee /etc/apt/sources.list.d/yarn.list > /dev/null
fi

sudo apt update
sudo apt install -y --no-install-recommends yarn


# Clone rl-swarm repo
echo "==> Cloning rl-swarm repository..."
if [ -d "rl-swarm" ]; then
  echo "Directory rl-swarm already exists; pulling latest changes..."
  cd rl-swarm
  git pull
else
  git clone https://github.com/gensyn-ai/rl-swarm.git
  cd rl-swarm
fi

echo "==> Please import your swarn.pem file now."
sleep 15

# Set up Python virtual environment
echo "==> Creating and activating Python venv..."
python3 -m venv .venv
# shellcheck disable=SC1091
source .venv/bin/activate

# Install frontend dependencies
echo "==> Installing and upgrading frontend (Modal login)..."
cd modal-login
yarn install
yarn upgrade
yarn add next@latest viem@latest

# Return to project root and launch
echo "==> Launching rl-swarm..."
cd ..
./run_rl_swarm.sh
#!/usr/bin/env bash
set -euo pipefail

# Update & install base packages
echo "==> Updating APT and installing Python, curl, wget, screen, git, lsof..."
sudo apt update
sudo apt install -y python3 python3-venv python3-pip curl wget screen git lsof

# Install Node.js 20.x
echo "==> Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt update
sudo apt install -y nodejs

# Add Yarn GPG key & repository (with fallback)
echo "==> Setting up Yarn keyring and repository..."
sudo mkdir -p /etc/apt/keyrings

if curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo tee /etc/apt/keyrings/yarn.gpg > /dev/null; then
  echo "Primary keyring import succeeded."
  echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" | \
     sudo tee /etc/apt/sources.list.d/yarn.list
else
  echo "Primary import failed – falling back to legacy apt-key method."
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg \
    | sudo apt-key add -
  echo "deb https://dl.yarnpkg.com/debian/ stable main" \
    | sudo tee /etc/apt/sources.list.d/yarn.list > /dev/null
fi

# Install Yarn
sudo apt update
sudo apt install -y --no-install-recommends yarn

# Clone rl-swarm repo
echo "==> Cloning rl-swarm repository..."
if [ -d "rl-swarm" ]; then
  echo "Directory rl-swarm already exists; pulling latest changes..."
  cd rl-swarm
  git pull
else
  git clone https://github.com/gensyn-ai/rl-swarm.git
  cd rl-swarm
fi

# Set up Python virtual environment
echo "==> Creating and activating Python venv..."
python3 -m venv .venv
# shellcheck disable=SC1091
source .venv/bin/activate

# Install frontend dependencies
echo "==> Installing and upgrading frontend (Modal login)..."
cd modal-login
yarn install
yarn upgrade
yarn add next@latest viem@latest

# Return to project root and launch
echo "==> Launching rl-swarm..."
cd ..
./run_rl_swarm.sh
