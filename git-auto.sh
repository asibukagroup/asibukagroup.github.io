#!/bin/bash

# Pull latest changes
git pull origin main

# Stage all files
git add .

# Commit changes with a message (use default or passed as argument)
if [ -z "$1" ]; then
  COMMIT_MSG="Auto update on $(date)"
else
  COMMIT_MSG="$1"
fi

git commit -m "$COMMIT_MSG"

# Push to GitHub
git push origin main
