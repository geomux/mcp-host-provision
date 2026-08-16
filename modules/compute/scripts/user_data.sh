#!/bin/bash
# user_data.sh
# Bash script to run the mcp-host-configure Ansible repo.
# Configures the provisioned host to hold and run the remote MCP server.


### -----------------
### --- CONSTANTS ---
### -----------------

REPO_URL="https://github.com/geomux/mcp-host-configure.git"
REPO_DIR="/opt/mcp-host-configure"
STATE_DIR="/opt/mcp-host-provision"

SERVER_NAME="mcp-cloud-box"
SERVER_PORT="9000"
SERVER_PATH="/mcp"


### ------------------------
### --- COMMAND SETTINGS ---
### ------------------------

set -e # exit immediately if any command fails
set -x # enables 'verbose' commands (i.e. print each command to log right before running for debugging)


### ------------------------
### --- INSTALL PACKAGES ---
### ------------------------

export DEBIAN_FRONTEND=noninteractive
apt-get -o DPkg::Lock::Timeout=600 update
apt-get -o DPkg::Lock::Timeout=600 install -y pipx python3 openssl git

export PIPX_HOME="/opt/pipx"
export PIPX_BIN_DIR="/usr/local/bin"
pipx install --include-deps ansible


### -------------------------------------
### --- CLONE REPO & ASSIGN INVENTORY ---
### -------------------------------------

rm -rf $REPO_DIR # Remove existing folder (not that it should exist on a new EC2 instance... but ya)
git clone "$REPO_URL" "$REPO_DIR"
cd "$REPO_DIR"

mkdir -p inventory

cat > inventory/hosts.yaml <<EOF
mcp_hosts:
  hosts:
    localhost:
      ansible_connection: local
      ansible_python_interpreter: /usr/bin/python3
EOF


### ----------------------------------
### --- CREATE & SECURE AUTH TOKEN ---
### ----------------------------------

set +x # disable 'verbose' commands (to avoide printing the auth token to the log)

TOKEN=$(openssl rand -hex 32)

mkdir -p group_vars

cat > group_vars/all.yaml <<EOF
mcp_server_name: "$SERVER_NAME"
mcp_server_port: $SERVER_PORT
mcp_server_path: "$SERVER_PATH"
mcp_auth_token: "$TOKEN"
EOF

mkdir -p "$STATE_DIR"

echo "$TOKEN" > "$STATE_DIR/mcp_auth_token.txt"

chmod 600 "$STATE_DIR/mcp_auth_token.txt"
chmod 600 "group_vars/all.yaml"

set -x # re-enable 'verbose' commands


### ----------------------------
### --- RUN ANSIBLE PLAYBOOK ---
### ----------------------------

ansible-playbook -i inventory/hosts.yaml playbook.yaml


### ---------------------
### --- CLEANUP & LOG ---
### ---------------------

date > "$STATE_DIR/provision-complete"
echo "Provisioning complete. Remote MCP Server deployed."
echo "Auth token saved to $STATE_DIR/mcp_auth_token.txt"
