#!/usr/bin/env bash
set -euo pipefail # Strict

# Load envs from .env.secrets
if [ -f ".env.secrets" ]; then
  source .env.secrets
fi

# Try to get credentials from environment variables first
username=${ARTIFACTORY_USERNAME:-${ARTIFACTORY_USER_NAME:-}}
password=${ARTIFACTORY_TOKEN:-${ARTIFACTORY_ACCESS_TOKEN:-}}

# If either credential is missing, prompt for input
if [ -z "$username" ]; then
  echo -n "Enter Artifactory Username: "
  read -r username
fi

if [ -z "$password" ]; then
  echo -n "Enter Artifactory Password (Hidden): "
  read -r -s password
  echo
fi

# Add credentials to .netrc file - used by pip and uv
cat > "$HOME/.netrc" << EOF

machine physicsx.jfrog.io
login $username
password $password

EOF

# Set proper permissions
chmod 600 "$HOME/.netrc"

echo
echo Artifactory authentication set up complete!
echo