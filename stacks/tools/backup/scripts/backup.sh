#!/bin/bash
# backup.sh - Script to back up homelab application data and sync to OneDrive

# Configuration from environment variables
BACKUP_RETENTION=${BACKUP_RETENTION:-7}  # Default to keeping 7 days of backups
ONEDRIVE_SYNC=${ONEDRIVE_SYNC:-true}
TZ=${TZ:-UTC}
APP_CONFIG_DATA_PATH=${APP_CONFIG_DATA_PATH}

# Set up backup directory and timestamp
BACKUP_DIR="/backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_PATH="${BACKUP_DIR}/${TIMESTAMP}"
RCLONE_CONFIG="/rclone_config/rclone.conf"
ONEDRIVE_REMOTE="onedrive"
LOG_FILE="${BACKUP_DIR}/backup.log"

# Function to log messages
log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a $LOG_FILE
}

log "Starting backup process at ${TIMESTAMP}"

# Create backup directory for this run
mkdir -p "${BACKUP_PATH}"

# Back up appdata directories
log "Backing up app data directories"
find /data/appdata -maxdepth 1 -mindepth 1 -type d | while read app_dir; do
    app_name=$(basename "$app_dir")
    log "Backing up ${app_name}"
    tar -czf "${BACKUP_PATH}/${app_name}.tar.gz" -C /data/appdata "${app_name}" || log "Error backing up ${app_name}"
done

# Create a backup summary
log "Creating backup summary"
echo "Backup created at: ${TIMESTAMP}" > "${BACKUP_PATH}/backup-info.txt"
echo "Backed up applications:" >> "${BACKUP_PATH}/backup-info.txt"
ls -la ${BACKUP_PATH}/*.tar.gz | awk '{print $9}' >> "${BACKUP_PATH}/backup-info.txt"

# Create a single archive of all backups for easier transfer
log "Creating consolidated backup archive"
tar -czf "${BACKUP_DIR}/full-backup-${TIMESTAMP}.tar.gz" -C "${BACKUP_DIR}" "${TIMESTAMP}"

# Sync to OneDrive if enabled
if [ "$ONEDRIVE_SYNC" = "true" ] && [ -f "$RCLONE_CONFIG" ]; then
    log "Syncing backup to OneDrive"
    
    # Check if OneDrive remote exists in rclone config
    if rclone listremotes --config="$RCLONE_CONFIG" | grep -q "^${ONEDRIVE_REMOTE}:"; then
        log "Starting sync to OneDrive"
        rclone copy --config="$RCLONE_CONFIG" "${BACKUP_DIR}/full-backup-${TIMESTAMP}.tar.gz" "${ONEDRIVE_REMOTE}:/Backups/homelab/" || log "Error syncing to OneDrive"
    else
        log "Error: OneDrive remote not configured in rclone. Please set up rclone with OneDrive access."
    fi
else
    log "OneDrive sync is disabled or rclone config not found"
fi

# Cleanup old backups
log "Cleaning up old backups"
find "${BACKUP_DIR}" -name "full-backup-*" -type f -mtime +${BACKUP_RETENTION} -delete
find "${BACKUP_DIR}" -mindepth 1 -maxdepth 1 -type d -mtime +${BACKUP_RETENTION} -exec rm -rf {} \;

log "Backup process completed successfully"