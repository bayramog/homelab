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

When using this repository with Portainer's Git integration, the environment variables will be automatically recognized through the `env_file` directive in each stack YAML file. The `stack.env` file is referenced with a relative path from each Docker Compose file:

- In the root `docker-compose.yml`: `env_file: ./stack.env`
- In top-level stack files (e.g., `stacks/media/coremedia.yml`): `env_file: ../../stack.env`
- In service-specific files (e.g., `stacks/media/radarr/radarr.yml`): `env_file: ../../../stack.env`

This ensures that Portainer can locate and use the environment file regardless of which stack you are deploying.
