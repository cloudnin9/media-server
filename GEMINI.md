# Project Overview

This project provides a complete media server setup using Docker. It includes the following services:

* **Jellyfin:** A free and open-source media server.
* **Jellyseerr:** A request management UI for Jellyfin.
* **SABnzbd:** A Usenet download client.
* **Sonarr:** For automating TV show downloads.
* **Radarr:** For automating movie downloads.
* **Prowlarr:** For managing indexers for Sonarr and Radarr.

The setup is designed to be run on either Windows 11 or Ubuntu LTS.

## Building and Running

### 1. Prerequisites

* Docker and Docker Compose must be installed.
* For Windows, PowerShell is used for setup scripts.

### 2. Environment Variables

Create a `.env` file in the project root directory with the following variables:

```
# Base paths (e.g., D:\MediaServer\config or /opt/mediaserver/config)
CONFIG_PATH=<path_to_config_folder>
DATA_PATH=<path_to_data_folder>

# User/Group IDs (use 1000 for Windows/WSL)
PUID=1000
PGID=1000

# Timezone (e.g., America/New_York)
TZ=<your_timezone>

# Jellyfin network discovery URL
JELLYFIN_PublishedServerUrl=http://<server_ip>:8096

# Application ports
JELLYFIN_PORT=8096
JELLYSEERR_PORT=5055
SABNZBD_PORT=8080
SONARR_PORT=8989
RADARR_PORT=7878
PROWLARR_PORT=9696
```

## 3. Running the Stack

To run the media server, execute the following command in the project root directory:

```bash
docker compose up -d
```

To stop the media server, run:

```bash
docker compose down
```

### 4. Windows Setup

For Windows users, there are two PowerShell scripts to help with the setup process:

* `create-directories.ps1`: This script creates the necessary folder structure for the media server. Before running, you can edit the script to change the base directory (default is `C:\MediaServer`).
* `add-host-alias.ps1`: This script adds a hostname alias to your Windows machine, allowing you to access the server using a custom name on your network (e.g., `http://mediaserver:8096`). You can edit the script to change the alias name.

To run these scripts, open PowerShell as an administrator and execute them.

## Development Conventions

* The `docker-compose.yml` file defines all the services and their configurations.
* Environment variables are used to configure the services, with examples provided in `.env.example`.
* PowerShell scripts are provided for setting up the required directory structure and network configuration on Windows.
* The `README.MD` file provides detailed instructions for setting up and configuring the entire media server stack.
