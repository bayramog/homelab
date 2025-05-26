#!/bin/bash

# Script to manually trigger a backup

echo "Triggering backup..."
docker exec backup sh -c "perform_backup"

echo "Backup completed!"