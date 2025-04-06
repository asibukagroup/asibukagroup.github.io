#!/bin/bash

# Add all changes
git add .

# Commit with timestamp message
git commit -m "Auto-update: $(date '+%Y-%m-%d %H:%M:%S')"

# Push to GitHub
git push origin main
