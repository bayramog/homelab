#!/bin/sh

# Create necessary directories
mkdir -p /backup/repository /backup/logs

# Initialize restic repository if not already initialized
restic snapshots || restic init

# Function to perform backup
perform_backup() {
  echo "Starting backup at $(date)"
  
  # Backup app configuration data
  restic backup /source \
    --exclude="/source/backup" \
    --tag homelab-config
  
  # Keep only the last 7 daily backups, last 4 weekly backups, and last 3 monthly backups
  restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 3 --prune
  
  echo "Backup completed at $(date)"
  
  # Sync to OneDrive if enabled
  if [ "$ONEDRIVE_SYNC_ENABLED" = "true" ]; then
    echo "Starting OneDrive sync at $(date)"
    
    # Check if rclone is configured
    if [ -f "/rclone-config/rclone.conf" ]; then
      # Sync the backup repository to OneDrive
      rclone sync /backup/repository onedrive:homelab-backups \
        --config=/rclone-config/rclone.conf \
        --log-file=/backup/logs/rclone-$(date +\%Y\%m\%d).log
      
      echo "OneDrive sync completed at $(date)"
    else
      echo "ERROR: rclone configuration not found. Cannot sync to OneDrive."
      echo "Please configure rclone with OneDrive first."
    fi
  fi
}

# If BACKUP_CRON is set, set up the cron job
if [ -n "$BACKUP_CRON" ]; then
  echo "Setting up cron job: $BACKUP_CRON"
  
  # Create a crontab file
  echo "$BACKUP_CRON /bin/sh -c \"perform_backup >> /backup/logs/backup-\$(date +\%Y\%m\%d).log 2>&1\"" > /tmp/backup-crontab
  
  # Install the crontab
  crontab /tmp/backup-crontab
  
  # Start cron in the foreground
  echo "Starting cron daemon..."
  crond -f -l 8
else
  # If no cron is set, just run the backup once and exit
  perform_backup
fi