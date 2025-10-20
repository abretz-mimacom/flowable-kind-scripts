#!/bin/bash

set -o errexit

echo
echo "Please provide values for the following:"
  
# Prompt for ARC_TOKEN
if [ -n "$ARC_TOKEN" ]; then
    read -rsp "Flowable repository password [****]: " input
    echo
    ARC_TOKEN="${input:-$ARC_TOKEN}"
else
    read -rsp "Flowable repository password: " ARC_TOKEN
    echo
fi
  
if [ -z "$ARC_TOKEN" ]; then
    echo "Error: ARC_TOKEN is required."
    exit 1
fi

  # Attempt to store as Codespace secrets if running in Codespaces
if [ -n "$CODESPACE_NAME" ]; then
    echo
    echo "Attempting to store variables as Codespace secrets..."
    
    if gh codespace secrets set ARC_TOKEN -b "$ARC_TOKEN" 2>/dev/null; then
      echo "✓ Successfully stored ARC_TOKEN"
    else
      echo "⚠ Warning: Failed to store ARC_TOKEN"
    fi
fi

echo
echo
echo 
echo "Adding env secrets to .bashrc"
echo $ARC_TOKEN >> ~/.bashrc

/bin/bash -c "echo Opening new shell to get updated .bashrc."
echo
echo
echo