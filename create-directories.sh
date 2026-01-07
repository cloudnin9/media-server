#!/bin/bash

# Define the base directory for the media server
# Defaulting to /opt/mediaserver as per Ubuntu/Linux conventions.
# You can change this to your preferred path.
BASE_DIR="/opt/mediaserver"

echo "Creating folder structure at $BASE_DIR"

# Create directories for Docker and various configurations
mkdir -p "$BASE_DIR/docker"
mkdir -p "$BASE_DIR/config/jellyfin"
mkdir -p "$BASE_DIR/config/jellyseerr"
mkdir -p "$BASE_DIR/config/sabnzbd"
mkdir -p "$BASE_DIR/config/sonarr"
mkdir -p "$BASE_DIR/config/radarr"
mkdir -p "$BASE_DIR/config/prowlarr"

# Create directories for data storage (usenet and media)
mkdir -p "$BASE_DIR/data/usenet/complete"
mkdir -p "$BASE_DIR/data/usenet/incomplete"
mkdir -p "$BASE_DIR/data/media/movies"
mkdir -p "$BASE_DIR/data/media/tv"

echo "Folder structure created at $BASE_DIR"