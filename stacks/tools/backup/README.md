# Backup Solution for Homelab

This directory contains the backup solution for the Homelab project. It uses [restic](https://restic.net/) for creating backups and [rclone](https://rclone.org/) for syncing backups to OneDrive.

## Configuration

The backup solution is configured through environment variables in the `backup_config.env` file:

```env
# Password for restic repository encryption 
BACKUP_PASSWORD=change-me-to-a-secure-password

# Cron schedule for backups (default: daily at 2 AM)
BACKUP_CRON=0 2 * * *

# Enable sync to OneDrive (true/false)
ONEDRIVE_SYNC_ENABLED=false
```

## Setup Instructions

1. Copy the sample configuration file:
   ```sh
   cp backup_config.env.sample backup_config.env
   ```

2. Edit the configuration file to set a secure password and adjust the backup schedule if needed:
   ```sh
   nano backup_config.env
   ```

3. Set up rclone for OneDrive (if you want to sync backups to OneDrive):
   ```sh
   docker exec -it rclone rclone config
   ```
   Follow the prompts to set up OneDrive as a remote named "onedrive".

4. Enable OneDrive sync in the backup_config.env file by setting `ONEDRIVE_SYNC_ENABLED=true`

## Backup Contents

By default, the backup solution backs up all application configuration data stored in the directory specified by the `APP_CONFIG_PATH` environment variable. 

## Backup Schedule

Backups are performed according to the cron schedule specified in the `BACKUP_CRON` environment variable. The default is daily at 2 AM.

## Backup Retention Policy

The backup solution keeps:
- Last 7 daily backups
- Last 4 weekly backups
- Last 3 monthly backups

Older backups are automatically removed to save space.

## Manual Backup

To perform a manual backup, run the provided script:
```sh
./run-backup.sh
```

This script triggers a backup immediately, regardless of the scheduled time.

## Restoring from Backup

To restore from a backup, use the following steps:

1. List available snapshots:
   ```sh
   docker exec -it backup restic snapshots
   ```

2. Restore from a specific snapshot (replace SNAPSHOT_ID with the actual snapshot ID):
   ```sh
   docker exec -it backup restic restore SNAPSHOT_ID --target /tmp/restore
   ```

3. The restored files will be available in the container at `/tmp/restore`. You can then copy them to their original location as needed.