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
