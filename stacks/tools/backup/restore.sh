#!/bin/bash

# Homelab Backup Restore Script
# This script helps you restore backups using Docker Compose

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
Homelab Backup Restore Script

Usage: $0 [OPTIONS]

OPTIONS:
    -s, --snapshot ID       Snapshot ID to restore (default: latest)
    -p, --path PATH         Specific path to restore (optional)
    -t, --target DIR        Target directory for restore (default: ./restore)
    -l, --list-only         Only list snapshots, don't restore
    -n, --no-download       Skip OneDrive download, use local repository
    -h, --help              Show this help message

EXAMPLES:
    # List available snapshots
    $0 --list-only
    
    # Restore latest snapshot
    $0
    
    # Restore specific snapshot
    $0 --snapshot abc123def
    
    # Restore specific path from latest snapshot
    $0 --path "/source/portainer"
    
    # Restore to custom directory
    $0 --target "/tmp/my-restore"
    
    # Restore without downloading from OneDrive (use local backup)
    $0 --no-download

ENVIRONMENT VARIABLES:
    The script uses the same .env file as your homelab stack.
    Make sure the following variables are set:
    - APP_CONFIG_PATH
    - TZ, PUID, PGID (optional)

EOF
}

# Default values
SNAPSHOT_ID="latest"
RESTORE_PATH=""
RESTORE_TARGET=""
LIST_ONLY="false"
DOWNLOAD_FROM_ONEDRIVE="true"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--snapshot)
            SNAPSHOT_ID="$2"
            shift 2
            ;;
        -p|--path)
            RESTORE_PATH="$2"
            shift 2
            ;;
        -t|--target)
            RESTORE_TARGET="$2"
            shift 2
            ;;
        -l|--list-only)
            LIST_ONLY="true"
            shift
            ;;
        -n|--no-download)
            DOWNLOAD_FROM_ONEDRIVE="false"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option $1"
            show_help
            exit 1
            ;;
    esac
done

# Check if .env file exists
if [ ! -f "../../../.env" ]; then
    print_error ".env file not found at ../../../.env"
    print_error "Make sure you're running this script from the backup directory"
    exit 1
fi

# Load environment variables
source ../../../.env

# Validate required environment variables
if [ -z "$APP_CONFIG_PATH" ]; then
    print_error "APP_CONFIG_PATH environment variable is required"
    exit 1
fi

# Set default restore target if not specified
if [ -z "$RESTORE_TARGET" ]; then
    RESTORE_TARGET="$APP_CONFIG_PATH/restore"
fi

print_status "Starting Homelab Backup Restore"
print_status "Configuration:"
echo "  Snapshot: $SNAPSHOT_ID"
echo "  Path: ${RESTORE_PATH:-'(entire snapshot)'}"
echo "  Target: $RESTORE_TARGET"
echo "  Download from OneDrive: $DOWNLOAD_FROM_ONEDRIVE"
echo "  List only: $LIST_ONLY"

# Create restore directory
mkdir -p "$RESTORE_TARGET"

# Export environment variables for docker-compose
export RESTORE_SNAPSHOT="$SNAPSHOT_ID"
export RESTORE_PATH="$RESTORE_PATH"
export RESTORE_TARGET="$RESTORE_TARGET"
export DOWNLOAD_FROM_ONEDRIVE="$DOWNLOAD_FROM_ONEDRIVE"

if [ "$LIST_ONLY" = "true" ]; then
    print_status "Listing snapshots only..."
    # Create a temporary compose file for listing
    cat > /tmp/restore-list.yml << EOF
services:
  backup-list:
    image: restic/restic:latest
    container_name: backup-list
    volumes:
      - ${APP_CONFIG_PATH}/backup:/backup:ro
      - ${APP_CONFIG_PATH}/rclone:/rclone-config:ro
    environment:
      - RESTIC_REPOSITORY=/backup/repository
      - DOWNLOAD_FROM_ONEDRIVE=${DOWNLOAD_FROM_ONEDRIVE}
    entrypoint: ["/bin/sh"]
    command:
      - "-c"
      - |
        apk add --no-cache rclone jq
        if [ "\$DOWNLOAD_FROM_ONEDRIVE" = "true" ]; then
          echo "Downloading backup index from OneDrive..."
          rclone sync onedrive:homelab-backups /backup/repository --config=/rclone-config/rclone.conf
        fi
        export RESTIC_REPOSITORY=/backup/repository
        echo "=== Available Snapshots ==="
        restic snapshots --insecure-no-password
EOF
    
    docker-compose -f /tmp/restore-list.yml up --remove-orphans
    docker-compose -f /tmp/restore-list.yml down
    rm /tmp/restore-list.yml
else
    print_status "Starting restore process..."
    
    # Run the restore
    docker-compose -f restore.yml up --remove-orphans
    
    if [ $? -eq 0 ]; then
        print_success "Restore completed!"
        print_success "Files are available in: $RESTORE_TARGET"
        
        # Clean up
        print_status "Cleaning up containers..."
        docker-compose -f restore.yml down
        
        print_status "Next steps:"
        echo "1. Review restored files: ls -la '$RESTORE_TARGET'"
        echo "2. Copy needed files to your homelab configuration"
        echo "3. Clean up restore directory when done: rm -rf '$RESTORE_TARGET'"
    else
        print_error "Restore failed!"
        print_status "Cleaning up..."
        docker-compose -f restore.yml down
        exit 1
    fi
fi

print_success "Script completed!"
