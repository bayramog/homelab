# homelab
Automated Homelab installation with Docker Compose

## Environment Variables

This project uses environment variables to standardize configuration across different services. The variables are defined in the `stack.env` file and can be easily modified to match your environment.

### Available Variables

- `APP_CONFIG_PATH`: Path for application configuration data (default: /mnt/internal-ssd/appdata)
- `MEDIA_PATH`: Path for media data (default: /mnt/mnt/media/data)
- `TZ`: Timezone (default: Europe/Istanbul)
- `PUID`: User ID for service permissions (default: 3000)
- `PGID`: Group ID for service permissions (default: 3000)
- `UMASK`: File permission mask (default: 022)
- `DATA_PATH`: Common path for data inside containers (default: /data)
- `RESTART_POLICY`: Container restart policy (default: unless-stopped)

### Usage with Portainer

When using this repository with Portainer's Git integration, you need to manually specify the path to the `stack.env` file in Portainer when deploying a stack. The `stack.env` file is located at the root of the repository.

In Portainer:
1. Select "Use environment variables from a file" option
2. Enter the path to the environment file: `stack.env` 

This ensures that Portainer can locate and use the environment file regardless of which stack you are deploying.

## Backup Solution

This project includes an automated backup solution that backs up all application configuration data and can sync to OneDrive.

### Features

- Automated backups using restic
- Configurable backup schedule via cron
- Data deduplication and compression
- Encrypted backups
- Configurable retention policy
- OneDrive integration via rclone

### Setup

1. Navigate to the backup configuration directory:
   ```
   stacks/tools/backup/
   ```

2. Copy the sample configuration file:
   ```
   cp backup_config.env.sample backup_config.env
   ```

3. Edit the configuration file with your desired settings:
   ```
   nano backup_config.env
   ```

4. For OneDrive integration, configure rclone:
   ```
   docker exec -it rclone rclone config
   ```

For detailed instructions, see the [backup README](stacks/tools/backup/README.md).
