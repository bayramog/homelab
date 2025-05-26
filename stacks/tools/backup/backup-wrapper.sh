#!/bin/sh

# This script starts the backup container with proper settings
# It handles both cron scheduling and one-time backup scenarios

# Check for required environment variable
if [ -z "$RESTIC_PASSWORD" ]; then
  echo "ERROR: RESTIC_PASSWORD environment variable must be set"
  exit 1
fi

# Create the backup script that will be executed by cron or manually
cat << 'EOF' > /tmp/backup-script.sh
#!/bin/sh

# Log start time
echo "Backup started at $(date)"

# Run restic backup
restic backup /source \
  --exclude="/source/backup" \
  --tag homelab-config

# Prune old backups
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 3 --prune

# Check if OneDrive sync is enabled
if [ "$ONEDRIVE_SYNC_ENABLED" = "true" ]; then
  # Check if rclone is configured
  if [ -f "/rclone-config/rclone.conf" ]; then
    echo "Syncing to OneDrive at $(date)"
    rclone sync /backup/repository onedrive:homelab-backups \
      --config=/rclone-config/rclone.conf \
      --log-file=/backup/logs/rclone-$(date +%Y%m%d).log
  else
    echo "WARNING: rclone configuration not found. Cannot sync to OneDrive."
  fi
fi

echo "Backup completed at $(date)"
EOF

chmod +x /tmp/backup-script.sh

# Initialize the restic repository if it doesn't exist
if ! restic snapshots > /dev/null 2>&1; then
  echo "Initializing restic repository..."
  restic init
fi

# Set up cron job if a schedule is provided
if [ -n "$BACKUP_CRON" ]; then
  echo "Setting up cron job with schedule: $BACKUP_CRON"
  echo "$BACKUP_CRON /tmp/backup-script.sh >> /backup/logs/backup.log 2>&1" > /tmp/crontab
  crontab /tmp/crontab
  
  echo "Starting cron daemon..."
  crond -f -l 8
else
  # Run backup once if no cron schedule
  echo "Running one-time backup..."
  /tmp/backup-script.sh
fi