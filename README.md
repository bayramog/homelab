# homelab
Automated Homelab installation with Docker Compose

## Backup Solution

This repo includes an automated backup solution that:
1. Creates daily backups of all application data
2. Supports syncing backups to OneDrive
3. Manages backup rotation to control disk usage

### Setting Up Backups

The backup system is configured to run automatically once the stack is deployed. By default:
- Backups run daily at 2:00 AM
- Backups are stored in `/mnt/cache/backups`
- Backups older than 7 days are automatically deleted

### OneDrive Sync Configuration

To enable syncing backups to OneDrive:

1. Make sure the rclone service is running:
   ```
   docker-compose --env-file stack.env -f docker-compose.yml up -d
   ```

2. Access the rclone web GUI at http://your-server-ip:5572
   - Username: bayramog
   - Password: 1234567890 (you should change this in rclone.yml)

3. Configure OneDrive in the rclone web GUI:
   - Click on 'Configs' tab
   - Click 'New remote'
   - Name: onedrive
   - Type: Microsoft OneDrive
   - Follow the authentication steps

For detailed guidance, run the helper script:
```
bash stacks/tools/backup/scripts/setup-onedrive.sh
```

### Customizing Backup Settings

You can customize the backup behavior by editing the environment variables in the backup.yml file:
- BACKUP_RETENTION: Number of days to keep backups (default: 7)
- BACKUP_SCHEDULE: Cron schedule for running backups (default: 0 2 * * *)
- ONEDRIVE_SYNC: Whether to sync to OneDrive (default: true)
