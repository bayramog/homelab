FROM restic/restic:latest

# Install required packages
RUN apk add --no-cache \
    busybox-suid \
    tzdata \
    curl \
    ca-certificates \
    rclone

# Create directory for scripts
RUN mkdir -p /scripts

# Set up entrypoint
ENTRYPOINT ["/bin/sh"]