#!/usr/bin/env bash
set -euo pipefail

# Define colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}==> Updating APT and installing Python, curl, wget, screen, git, lsof...${NC}"
sudo apt update
sudo apt install -y python3 python3-venv python3-pip curl wget screen git lsof

echo -e "${GREEN}==> Installing Node.js 20.x...${NC}"
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt update
sudo apt install -y nodejs

echo -e "${CYAN}==> Setting up Yarn keyring and repository...${NC}"
sudo mkdir -p /etc/apt/keyrings

if curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /etc/apt/keyrings/yarn.gpg > /dev/null; then
  echo -e "${GREEN}Primary keyring import succeeded.${NC}"
  sudo chmod 644 /etc/apt/keyrings/yarn.gpg
  echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
else
  echo -e "${RED}Primary import failed – falling back to legacy apt-key method.${NC}"
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list > /dev/null
fi

sudo apt update
sudo apt install -y --no-install-recommends yarn

echo -e "${YELLOW}==> Cloning rl-swarm repository...${NC}"
if [ -d "rl-swarm" ]; then
  echo -e "${MAGENTA}Directory rl-swarm already exists; pulling latest changes...${NC}"
  cd rl-swarm
  git pull
else
  git clone https://github.com/gensyn-ai/rl-swarm.git
  cd rl-swarm
fi

echo -e "${BLUE}==> Please import your swarn.pem file now.${NC}"
sleep 15

echo -e "${GREEN}==> Creating and activating Python venv...${NC}"
python3 -m venv .venv
# shellcheck disable=SC1091
source .venv/bin/activate

echo -e "${CYAN}==> Installing and upgrading frontend (Modal login)...${NC}"
cd modal-login
yarn install
yarn upgrade
yarn add next@latest viem@latest

echo -e "${YELLOW}==> Launching rl-swarm...${NC}"
cd ..
./run_rl_swarm.sh
