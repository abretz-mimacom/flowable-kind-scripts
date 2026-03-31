#!/bin/bash

  echo "Please provide values for the following:"
  echo
  
  # Prompt for FLOWABLE_REPO_USER
if [ -n "$FLOWABLE_REPO_USER" ]; then
    read -rp "Flowable repository username [$FLOWABLE_REPO_USER]: " input
    FLOWABLE_REPO_USER="${input:-$FLOWABLE_REPO_USER}"
else
    read -rp "Flowable repository username: " FLOWABLE_REPO_USER
fi
  
if [ -z "$FLOWABLE_REPO_USER" ]; then
    echo "Error: FLOWABLE_REPO_USER is required."
    exit 1
fi
  
# Prompt for FLOWABLE_REPO_PASSWORD
if [ -n "$FLOWABLE_REPO_PASSWORD" ]; then
    read -rsp "Flowable repository password [****]: " input
    echo
    FLOWABLE_REPO_PASSWORD="${input:-$FLOWABLE_REPO_PASSWORD}"
else
    read -rsp "Flowable repository password: " FLOWABLE_REPO_PASSWORD
    echo
fi
  
if [ -z "$FLOWABLE_REPO_PASSWORD" ]; then
    echo "Error: FLOWABLE_REPO_PASSWORD is required."
    exit 1
fi
  
  # Prompt for FLOWABLE_LICENSE_KEY
if [ -n "$FLOWABLE_LICENSE_PATH" ]; then
    read -rp "Flowable license key [$FLOWABLE_LICENSE_PATH]: " input
    FLOWABLE_LICENSE_PATH="${input:-$FLOWABLE_LICENSE_PATH}"
else
    read -rp "Flowable license file path: " FLOWABLE_LICENSE_PATH
fi

FLOWABLE_LICENSE_KEY="$(cat "$FLOWABLE_LICENSE_PATH" 2>/dev/null || echo "")"  

if [ -z "$FLOWABLE_LICENSE_KEY" ]; then
    echo "Error: FLOWABLE_LICENSE_KEY is required."
    exit 1
fi

    # Prompt for GITHUB_OAUTH_CLIENT_ID
if [ -n "$GITHUB_OAUTH_CLIENT_ID" ]; then
    read -rp "GitHub OAuth2 Client ID [$GITHUB_OAUTH_CLIENT_ID]: " input
    GITHUB_OAUTH_CLIENT_ID="${input:-$GITHUB_OAUTH_CLIENT_ID}"
else
    echo "Navigate to https://github.com/settings/applications/new?oauth_application[name]=flowable&oauth_application[url]=https://$CODESPACE_NAME-443.app.github.dev&oauth_application[callback_url]=https://$CODESPACE_NAME-443.app.github.dev \n and create an an oauth2 client application. Enter the ID/Secret in the prompts below."
    read -rp "GitHub Client ID: " GITHUB_OAUTH_CLIENT_ID
fi

if [ -z "$GITHUB_OAUTH_CLIENT_ID" ]; then
    echo "Error: GITHUB_OAUTH_CLIENT_ID is required."
    exit 1
fi

if [ -n "$GITHUB_OAUTH_CLIENT_SECRET" ]; then
    read -rp "GitHub OAuth2 Client Secret [*****]: " input
    GITHUB_OAUTH_CLIENT_SECRET="${input:-$GITHUB_OAUTH_CLIENT_SECRET}"
else
    read -rp "GitHub Client Secret: " GITHUB_OAUTH_CLIENT_SECRET
fi

if [ -z "$GITHUB_OAUTH_CLIENT_SECRET" ]; then
    echo "Error: GITHUB_OAUTH_CLIENT_SECRET is required."
    exit 1
fi 
  # Attempt to store as Codespace secrets if running in Codespaces
if [ -n "$CODESPACE_NAME" ]; then
    echo "FLOWABLE_REPO_USER=\"$FLOWABLE_REPO_USER\"" >> ~/secrets.txt
    echo "FLOWABLE_REPO_PASSWORD=\"$FLOWABLE_REPO_PASSWORD\"" >> ~/secrets.txt
    echo "FLOWABLE_LICENSE_KEY=\"$FLOWABLE_LICENSE_KEY\"" >> ~/secrets.txt
    echo "GITHUB_OAUTH_CLIENT_ID=\"$GITHUB_OAUTH_CLIENT_ID\"" >> ~/secrets.txt
    echo "GITHUB_OAUTH_CLIENT_SECRET=\"$GITHUB_OAUTH_CLIENT_SECRET\"" >> ~/secrets.txt
    echo
    echo "Attempting to store variables as Codespace secrets..."
    
    if gh secret set --user -f - < ~/secrets.txt 2>/dev/null; then
      echo "✓ Successfully stored secrets"
    else
      echo "⚠ Warning: Failed to store secrets to codespaces secrets. It is possible you lack the permissions to do so."
    fi
    
    rm ~/secrets.txt

    echo
    echo 
    echo "Adding env secrets to .bashrc for convenience"
    echo "export FLOWABLE_REPO_USER=\"$FLOWABLE_REPO_USER\"" >> ~/.bashrc
    echo "export FLOWABLE_REPO_PASSWORD=\"$FLOWABLE_REPO_PASSWORD\"" >> ~/.bashrc
    echo "export FLOWABLE_LICENSE_PATH=\"$FLOWABLE_LICENSE_PATH\"" >> ~/.bashrc
    echo "export FLOWABLE_LICENSE_KEY=\"$FLOWABLE_LICENSE_KEY\"" >> ~/.bashrc
    echo "export GITHUB_OAUTH_CLIENT_ID=\"$GITHUB_OAUTH_CLIENT_ID\"" >> ~/.bashrc
    echo "export GITHUB_OAUTH_CLIENT_SECRET=\"$GITHUB_OAUTH_CLIENT_SECRET\"" >> ~/.bashrc
    
    /bin/bash -c "echo \"Opening new shell to use env secrets.\""
    echo
    echo

    # if gh codespace secrets set FLOWABLE_REPO_PASSWORD -b "$FLOWABLE_REPO_PASSWORD" 2>/dev/null; then
    #   echo "✓ Successfully stored FLOWABLE_REPO_PASSWORD"
    # else
    #   echo "⚠ Warning: Failed to store FLOWABLE_REPO_PASSWORD"
    # fi
    
    # if gh codespace secrets set FLOWABLE_LICENSE_KEY -b "$FLOWABLE_LICENSE_KEY" 2>/dev/null; then
    #   echo "✓ Successfully stored FLOWABLE_LICENSE_KEY"
    # else
    #   echo "⚠ Warning: Failed to store FLOWABLE_LICENSE_KEY"
    # fi
fi
