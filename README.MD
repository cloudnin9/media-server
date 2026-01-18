# Complete Media Server Setup Guide
## Jellyfin + Jellyseerr + Usenet + Docker Stack

This guide walks you through setting up a complete automated media server from scratch on **Windows 11** or **Ubuntu LTS**.

---

## Table of Contents
1. [Architecture Overview](#1-architecture-overview)
2. [Usenet: Providers & Indexers](#2-usenet-providers--indexers)
3. [Folder Structure](#3-folder-structure)
4. [Docker Installation](#4-docker-installation)
5. [Docker Compose Stack](#5-docker-compose-stack)
6. [Application Configuration](#6-application-configuration)
7. [Connecting Everything Together](#7-connecting-everything-together)
8. [Connecting Devices to Jellyfin](#8-connecting-devices-to-jellyfin)
9. [Remote Access (Optional)](#9-remote-access-optional)
10. [Windows Network Configuration](#10-windows-network-configuration)
11. [Hardware Transcoding Setup (Linux)](#11-hardware-transcoding-setup-linux)
12. [Troubleshooting](#12-troubleshooting)
13. [Maintenance & Tips](#13-maintenance--tips)
14. [Advanced: Spotweb (Self-Hosted Indexer)](#14-advanced-spotweb-self-hosted-indexer)

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        YOUR REQUESTS                            │
│                   (Jellyseerr / Manual)                         │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                 AUTOMATION LAYER                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Sonarr    │  │   Radarr    │  │       Prowlarr          │  │
│  │  (TV Shows) │  │  (Movies)   │  │  (Indexer Management)   │  │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘  │
└─────────┼────────────────┼─────────────────────┼────────────────┘
          │                │                     │
          ▼                ▼                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DOWNLOAD LAYER                               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    SABnzbd                               │   │
│  │              (Usenet Download Client)                    │   │
│  └──────────────────────────┬───────────────────────────────┘   │
└─────────────────────────────┼───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     STORAGE                                     │
│           /data/media/movies  &  /data/media/tv                 │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      MEDIA SERVER                               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                     Jellyfin                             │   │
│  │         (Free, Open-Source Media Streaming)              │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Components

| Application | Purpose | Port |
|-------------|---------|------|
| **Jellyfin** | Free, open-source media server | 8096 |
| **Jellyseerr** | Request management UI for Jellyfin | 5055 |
| **SABnzbd** | Downloads NZB files from Usenet | 8080 |
| **Sonarr** | Automates TV show downloads | 8989 |
| **Radarr** | Automates movie downloads | 7878 |
| **Prowlarr** | Manages indexers for Sonarr/Radarr | 9696 |

### Why Jellyfin?

| Feature | Jellyfin |
|---------|----------|
| **Cost** | 100% Free and open-source |
| **Hardware Transcoding** | Free (no subscription required) |
| **Mobile Apps** | Free on all platforms |
| **Account Required** | No - fully self-hosted |
| **Privacy** | Complete control, no external dependencies |

---

## 2. Usenet: Providers & Indexers

You need **two things** to use Usenet:

### 2.1 Usenet Provider (Required)
This is your access to Usenet servers. Think of it like an ISP for Usenet.

#### Recommended Providers

| Provider | Backbone | Retention | Price | Notes |
|----------|----------|-----------|-------|-------|
| **Newshosting** | UNS Holdings | 5800+ days | ~$3-5/mo (deals) | Great starter, often has deals |
| **Eweka** | Independent (EU) | 5400+ days | ~€4-7/mo | European, very reliable |
| **Frugal Usenet** | UNS Holdings | 5800+ days | ~$5/mo | Budget-friendly reseller |
| **UsenetExpress** | Independent | 5500+ days | ~$3-4/mo | Good for block accounts |

#### Pro Tips for Providers
- **Wait for Black Friday/holiday sales** - prices drop 50-70%
- **Start with one provider** - you can add a backup later
- **Block accounts** (pay per GB) are good backups for failed downloads
- Look for deals on r/usenet

### 2.2 Usenet Indexers (Required)
Indexers catalog what's available on Usenet and provide NZB files.

#### Recommended Indexers

| Indexer | Type | Cost | Notes |
|---------|------|------|-------|
| **NZBGeek** | Paid | $12/year | Excellent, highly recommended |
| **DrunkenSlug** | Paid | €10/year | Very good, invite sometimes needed |
| **NZBFinder** | Freemium | Free tier / €10/year | Good starter |
| **Tabula Rasa** | Free/Donation | Free | Decent free option |

#### Pro Tips for Indexers
- **Get 2-3 indexers** for best coverage
- Some indexers are invite-only - check r/usenet for invites
- NZBGeek is widely considered the best starting point

### 2.3 Getting Your Indexer API Key

You'll need an API key from each indexer to add it to Prowlarr. Here's how to find them:

#### NZBGeek
1. Go to https://nzbgeek.info
2. Register for an account and verify your email
3. Log in → click **My Account** (top right)
4. Find **API Key** — copy this long alphanumeric string

#### DrunkenSlug
1. Go to https://drunkenslug.com
2. Log in → go to **Profile** → **API**
3. Copy your API key

#### NZBFinder
1. Go to https://nzbfinder.ws
2. Log in → go to **Account** → **API**
3. Copy your API key

---

## 3. Folder Structure

A proper folder structure prevents permission issues and enables **hardlinks** (instant moves, no extra disk space during processing).

### Windows 11

```
D:\MediaServer\
├── docker\                    # Docker compose and config files
│   └── docker-compose.yml
├── config\                    # Application configs (persistent)
│   ├── jellyfin\
│   ├── jellyseerr\
│   ├── sabnzbd\
│   ├── sonarr\
│   ├── radarr\
│   └── prowlarr\
└── data\                      # All media and downloads
    ├── usenet\                # SABnzbd downloads
    │   ├── complete\
    │   └── incomplete\
    └── media\                 # Final media library
        ├── movies\
        └── tv\
```

### Ubuntu LTS

```
/opt/mediaserver/
├── docker/                    # Docker compose and config files
│   └── docker-compose.yml
├── config/                    # Application configs (persistent)
│   ├── jellyfin/
│   ├── jellyseerr/
│   ├── sabnzbd/
│   ├── sonarr/
│   ├── radarr/
│   └── prowlarr/
└── data/                      # All media and downloads
    ├── usenet/                # SABnzbd downloads
    │   ├── complete/
    │   └── incomplete/
    └── media/                 # Final media library
        ├── movies/
        └── tv/
```

### Why This Structure?

- **Single parent directory** (`data/`) allows hardlinks between downloads and media
- **Hardlinks** = instant file "moves" using zero additional space
- All apps see the same path structure inside Docker
- Configs are separate and easy to backup

Note on host vs container paths: Docker volume mappings are `host_path:container_path`. Configure each application using the container-side path (the right-hand side). For example, if you mount `${DATA_PATH}/media/tv:/data/media/tv`, Sonarr/Radarr should use `/data/media/tv` as their root; Jellyfin may mount the same host folder into its container at `/data/tvshows` — always use the container path when configuring apps.

---

## 4. Docker Installation

### Windows 11

#### Step 1: Install Docker Desktop

1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop/
2. Run the installer
3. **Enable WSL 2 backend** when prompted (recommended)
4. Restart your computer when prompted
5. Launch Docker Desktop and complete the setup

#### Step 2: Verify Installation

Open PowerShell and run:

```powershell
docker --version
docker compose version
```

#### Step 3: Create Folder Structure

Open PowerShell as Administrator:

```powershell
# Create all directories (adjust D: to your preferred drive)
$base = "D:\MediaServer"

New-Item -ItemType Directory -Force -Path "$base\docker"
New-Item -ItemType Directory -Force -Path "$base\config\jellyfin"
New-Item -ItemType Directory -Force -Path "$base\config\jellyseerr"
New-Item -ItemType Directory -Force -Path "$base\config\sabnzbd"
New-Item -ItemType Directory -Force -Path "$base\config\sonarr"
New-Item -ItemType Directory -Force -Path "$base\config\radarr"
New-Item -ItemType Directory -Force -Path "$base\config\prowlarr"
New-Item -ItemType Directory -Force -Path "$base\data\usenet\complete"
New-Item -ItemType Directory -Force -Path "$base\data\usenet\incomplete"
New-Item -ItemType Directory -Force -Path "$base\data\media\movies"
New-Item -ItemType Directory -Force -Path "$base\data\media\tv"

Write-Host "Folder structure created at $base" -ForegroundColor Green
```

---

### Ubuntu LTS

#### Step 1: Install Docker Engine

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install prerequisites
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add your user to docker group (avoids needing sudo)
sudo usermod -aG docker $USER

# Apply group changes (or log out and back in)
newgrp docker
```

#### Step 2: Verify Installation

```bash
docker --version
docker compose version
```

#### Step 3: Create Folder Structure

1.  **Download the script:**
    ```bash
    wget https://raw.githubusercontent.com/cloudnin9/media-server/main/create-directories.sh -O create-directories.sh
    ```
    (Note: Replace `cloudnin9` with your GitHub username if you forked the repository)

2.  **Make the script executable:**
    ```bash
    chmod +x create-directories.sh
    ```
    
3.  **Run the script:**
    ```bash
    ./create-directories.sh
    ```
    This script will create the necessary folder structure at `/opt/mediaserver` by default. You can edit the `BASE_DIR` variable within the script if you wish to use a different path.

4.  **Set ownership to your user:**
    ```bash
    sudo chown -R $USER:$USER /opt/mediaserver
    ```

5.  **Verify:**
    ```bash
    ls -la /opt/mediaserver/
    ```

---

## 5. Docker Compose Stack

> **Important:** This configuration includes an explicit network definition to ensure containers can communicate using service names. This is especially important for Docker Desktop on Windows.

### 5.1 Environment Variables (.env File)

Using a `.env` file keeps your configuration in one place and makes it easy to customize paths, timezone, and user permissions.

#### Windows 11 - Create `.env` file

Save this as `D:\MediaServer\docker\.env`:

```env
# ===========================================
# MEDIA SERVER CONFIGURATION
# ===========================================

# Base paths (Windows format)
CONFIG_PATH=D:\MediaServer\config
DATA_PATH=D:\MediaServer\data

# User/Group IDs - Linux UID/GID
# On Linux find values with: `id $USER`.
# When using WSL, `1000` is a common UID/GID; native Docker Desktop on
# Windows ignores Linux UID/GID mapping for container file ownership.
PUID=1000
PGID=1000

# Timezone - find yours at: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
TZ=America/New_York

# ===========================================
# JELLYFIN NETWORK DISCOVERY
# ===========================================
# Set this to your server's IP address for auto-discovery on local network
# Find your IP with: ipconfig (look for IPv4 Address)
JELLYFIN_PublishedServerUrl=http://192.168.1.100:8096

# ===========================================
# APPLICATION PORTS (change if conflicts)
# ===========================================
JELLYFIN_PORT=8096
JELLYSEERR_PORT=5055
SABNZBD_PORT=8080
SONARR_PORT=8989
RADARR_PORT=7878
PROWLARR_PORT=9696
```

#### Ubuntu LTS - Create `.env` file

Save this as `/opt/mediaserver/docker/.env`:

```env
# ===========================================
# MEDIA SERVER CONFIGURATION
# ===========================================

# Base paths (Linux format)
CONFIG_PATH=/opt/mediaserver/config
DATA_PATH=/opt/mediaserver/data

# User/Group IDs - find yours with: `id $USER` on Linux
# Use the numeric UID/GID from the command output. If running via WSL,
# `1000` is commonly correct. Native Docker Desktop on Windows does not
# use these values the same way as Linux hosts.
PUID=1000
PGID=1000

# Render group ID for GPU access - find with: getent group render
RENDER_GROUP_ID=109

# Timezone - find yours at: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
TZ=America/New_York

# ===========================================
# JELLYFIN NETWORK DISCOVERY
# ===========================================
# Set this to your server's IP address for auto-discovery on local network
# Find your IP with: ip addr (look for inet under your network interface)
JELLYFIN_PublishedServerUrl=http://192.168.1.100:8096

# ===========================================
# APPLICATION PORTS (change if conflicts)
# ===========================================
JELLYFIN_PORT=8096
JELLYSEERR_PORT=5055
SABNZBD_PORT=8080
SONARR_PORT=8989
RADARR_PORT=7878
PROWLARR_PORT=9696
```

**Finding your PUID/PGID on Ubuntu:**
```bash
id $USER
# Output: uid=1000(username) gid=1000(username) ...
# Use the numbers after uid= and gid=
```

**Finding your Render Group ID (for GPU acceleration):**
```bash
getent group render
# Output: render:x:109:  <- use this number for RENDER_GROUP_ID
```

---

### 5.2 Docker Compose File

Save this as `docker-compose.yml` in the same folder as your `.env` file:

**Windows:** `D:\MediaServer\docker\docker-compose.yml`  
**Ubuntu:** `/opt/mediaserver/docker/docker-compose.yml`

```yaml
networks:
  mediaserver:
    name: mediaserver
    driver: bridge

services:
  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    networks:
      - mediaserver
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
      - JELLYFIN_PublishedServerUrl=${JELLYFIN_PublishedServerUrl}
    volumes:
      - ${CONFIG_PATH}/jellyfin:/config
      - ${DATA_PATH}/media/tv:/data/tvshows
      - ${DATA_PATH}/media/movies:/data/movies
    ports:
      - "${JELLYFIN_PORT}:8096"
      - "7359:7359/udp"
    # =====================================================
    # HARDWARE TRANSCODING - Uncomment based on your GPU:
    # =====================================================
    # For Intel/AMD GPUs (Linux):
    # devices:
    #   - /dev/dri:/dev/dri
    # group_add:
    #   - "${RENDER_GROUP_ID}"  # Find with: getent group render
    #
    # For NVIDIA GPUs (Linux) - requires nvidia-container-toolkit:
    # runtime: nvidia
    # environment:
    #   - NVIDIA_VISIBLE_DEVICES=all
    # =====================================================
    restart: unless-stopped

  jellyseerr:
    image: fallenbagel/jellyseerr:sha-82c5839 # latest did not work for me
    container_name: jellyseerr
    networks:
      - mediaserver
    environment:
      - LOG_LEVEL=info
      - TZ=${TZ}
    volumes:
      - ${CONFIG_PATH}/jellyseerr:/app/config
    ports:
      - "${JELLYSEERR_PORT}:5055"
    restart: unless-stopped
    depends_on:
      - jellyfin

  sabnzbd:
    image: lscr.io/linuxserver/sabnzbd:latest
    container_name: sabnzbd
    networks:
      - mediaserver
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - ${CONFIG_PATH}/sabnzbd:/config
      - ${DATA_PATH}:/data
    ports:
      - "${SABNZBD_PORT}:8080"
    restart: unless-stopped

  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    networks:
      - mediaserver
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - ${CONFIG_PATH}/sonarr:/config
      - ${DATA_PATH}:/data
    ports:
      - "${SONARR_PORT}:8989"
    restart: unless-stopped
    depends_on:
      - sabnzbd

  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    networks:
      - mediaserver
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - ${CONFIG_PATH}/radarr:/config
      - ${DATA_PATH}:/data
    ports:
      - "${RADARR_PORT}:7878"
    restart: unless-stopped
    depends_on:
      - sabnzbd

  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    networks:
      - mediaserver
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - ${CONFIG_PATH}/prowlarr:/config
    ports:
      - "${PROWLARR_PORT}:9696"
    restart: unless-stopped
```

> **Note:** This single `docker-compose.yml` works for both Windows and Ubuntu. The `.env` file handles the path differences.
>
> Modern Docker uses the `docker compose` CLI plugin (no hyphen). Older systems and scripts may still use `docker-compose` (with a hyphen).

---

### 5.3 Starting the Stack

**Windows 11** (PowerShell):
```powershell
cd D:\MediaServer\docker
docker compose up -d
```

**Ubuntu LTS**:
```bash
cd /opt/mediaserver/docker
docker compose up -d
```

### 5.4 Verify All Containers Are Running

```bash
docker ps
```

You should see all 6 containers with status "Up".

### 5.5 Verify Network Connectivity

Test that containers can reach each other by name:

```bash
docker exec sonarr ping -c 2 sabnzbd
```

If this works, DNS resolution is functioning correctly.

---

## 6. Application Configuration

### Access Points

After starting, access each application at:

| Application | URL |
|-------------|-----|
| Jellyfin | http://localhost:8096 |
| Jellyseerr | http://localhost:5055 |
| SABnzbd | http://localhost:8080 |
| Sonarr | http://localhost:8989 |
| Radarr | http://localhost:7878 |
| Prowlarr | http://localhost:9696 |

---

### 6.1 Configure SABnzbd

1. **Open** http://localhost:8080
2. Complete the **Quick-Start Wizard**
3. **Add your Usenet server:**
   - Settings → Servers → Add Server
   - Host: `news.yourprovider.com` (from your provider)
   - Port: `563` (SSL) or `119` (non-SSL)
   - SSL: ✓ Enable
   - Username/Password: Your provider credentials
   - Connections: Start with 20-30

4. **Configure folders:**
   - Settings → Folders
   - Temporary Download Folder: `/data/usenet/incomplete`
   - Completed Download Folder: `/data/usenet/complete`

5. **Get your API Key:**
   - Settings → General → API Key
   - Copy this - you'll need it for Sonarr/Radarr

6. **Configure Hostname Whitelist (Important for Docker):**
   
   SABnzbd blocks connections from unrecognized hostnames by default. You need to whitelist the container name:
   
   - Settings → Special
   - Find **host_whitelist**
   - Add: `sabnzbd, localhost`
   - Click **Save Changes**
   - Restart SABnzbd: `docker restart sabnzbd`
   
   **Alternative:** Edit `D:\MediaServer\config\sabnzbd\sabnzbd.ini` directly:
   ```ini
   host_whitelist = sabnzbd, localhost
   ```

---

### 6.2 Configure Prowlarr (Indexer Management)

1. **Open** http://localhost:9696

2. **Add Indexers:**
   - Go to **Indexers** in the left sidebar
   - Click the **+** button (Add Indexer)
   - Search for your indexer (e.g., "NZBGeek")
   - Click on the indexer from the list
   - Fill in the settings:
   
   | Field | Value |
   |-------|-------|
   | **Name** | NZBGeek (or any name you prefer) |
   | **Enable RSS** | ✓ Yes |
   | **Enable Automatic Search** | ✓ Yes |
   | **Enable Interactive Search** | ✓ Yes |
   | **API Key** | Paste your API key (see section 2.3) |
   
   - Click **Test** — you should see a green checkmark
   - Click **Save**
   
   Repeat for each indexer you have (recommended: 2-3 indexers for best coverage).

3. **Add Download Client:**
   - Settings → Download Clients → Add
   - Select "SABnzbd"
   - Host: `sabnzbd` (container name)
   - Port: `8080`
   - API Key: (from SABnzbd)
   - Test and Save

4. **Connect Prowlarr to Sonarr (Sync Indexers):**
   - Settings → Apps → Click **+** to add
   - Select "Sonarr"
   - Sync Level: **Full Sync**
   - Prowlarr Server: `http://prowlarr:9696`
   - Sonarr Server: `http://sonarr:8989`
   - API Key: *(get from Sonarr → Settings → General → API Key)*
   - Test and Save

5. **Connect Prowlarr to Radarr (Sync Indexers):**
   - Settings → Apps → Click **+** to add
   - Select "Radarr"
   - Sync Level: **Full Sync**
   - Prowlarr Server: `http://prowlarr:9696`
   - Radarr Server: `http://radarr:7878`
   - API Key: *(get from Radarr → Settings → General → API Key)*
   - Test and Save

6. **Sync Indexers to Apps:**
   - Click **Sync App Indexers** at the top of the Apps page
   - Your indexers will now appear in both Sonarr and Radarr automatically

### Adding Custom/Unsupported Indexers

If your indexer isn't in Prowlarr's list:

1. Click **+** → search for **"Generic Newznab"**
2. Fill in:
   - **Name:** Your indexer's name
   - **URL:** The indexer's API URL (found on their website)
   - **API Key:** Your API key
3. Test and Save

---

### 6.3 Configure Sonarr (TV Shows)

1. **Open** http://localhost:8989

2. **Verify Indexers Synced from Prowlarr:**
   - Go to Settings → Indexers
   - You should see your indexers already listed (synced from Prowlarr)
   - If not, go back to Prowlarr and click "Sync App Indexers"

3. **Add SABnzbd:**
   - Settings → Download Clients → Add
   - Select "SABnzbd"
   - Name: SABnzbd
   - Host: `sabnzbd`
   - Port: `8080`
   - API Key: (from SABnzbd)
   - Category: `tv` (create this category in SABnzbd)
   - Test and Save

4. **Configure Root Folder:**
   - Settings → Media Management → Root Folders → Add
   - Path: `/data/media/tv`

5. **Configure Quality Profiles:**
   - Settings → Profiles
   - Edit or create a profile (recommend starting with "HD-1080p")

---

### 6.4 Configure Radarr (Movies)

1. **Open** http://localhost:7878

2. **Verify Indexers Synced from Prowlarr:**
   - Go to Settings → Indexers
   - You should see your indexers already listed (synced from Prowlarr)
   - If not, go back to Prowlarr and click "Sync App Indexers"

3. **Add SABnzbd:**
   - Settings → Download Clients → Add
   - Select "SABnzbd"
   - Name: SABnzbd
   - Host: `sabnzbd`
   - Port: `8080`
   - API Key: (from SABnzbd)
   - Category: `movies` (create in SABnzbd)
   - Test and Save

4. **Configure Root Folder:**
   - Settings → Media Management → Root Folders → Add
   - Path: `/data/media/movies`

---

### 6.5 Configure Jellyfin

#### Initial Setup

1. **Open** http://localhost:8096
2. Complete the **Setup Wizard**:
   - Select your preferred language
   - Create an **admin username and password** (no external account needed!)
   - Add Libraries:
     - Add Library → Movies → Folder: `/data/movies`
     - Add Library → TV Shows → Folder: `/data/tvshows`
   - Configure metadata language
   - Enable remote access if desired

#### Configure Network Discovery (Published Server URL)

The `JELLYFIN_PublishedServerUrl` environment variable tells Jellyfin what URL to broadcast for auto-discovery on your local network. This helps client apps find your server automatically.

**Already configured in docker-compose.yml** via the `.env` file. If clients can't auto-discover your server:

1. Make sure `JELLYFIN_PublishedServerUrl` is set in your `.env` file:
   ```env
   JELLYFIN_PublishedServerUrl=http://192.168.1.100:8096
   ```
   Replace `192.168.1.100` with your server's actual IP address.

2. Restart Jellyfin:
   ```bash
   docker restart jellyfin
   ```

3. Verify in Jellyfin:
   - Dashboard → Networking
   - Check "LAN networks" includes your local subnet (e.g., `192.168.1.0/24`)

#### Enable Hardware Transcoding (Free!)

Hardware transcoding offloads video encoding/decoding to your GPU, dramatically reducing CPU usage and enabling smooth playback of high-bitrate content.

##### Step 1: Enable GPU Access in Docker

**For Intel/AMD GPUs (Linux):**

Uncomment the `devices` and `group_add` lines in `docker-compose.yml`:

```yaml
jellyfin:
  # ... other settings ...
  devices:
    - /dev/dri:/dev/dri
  group_add:
    - "109"  # render group - find yours with: getent group render
```

Find your render group ID:
```bash
getent group render
# Output: render:x:109:  <- use this number
```

**For NVIDIA GPUs (Linux):**

1. Install NVIDIA Container Toolkit on host:
   ```bash
   # Add NVIDIA repo
   distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
   curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
   curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
   
   # Install toolkit
   sudo apt update
   sudo apt install -y nvidia-container-toolkit
   sudo systemctl restart docker
   ```

2. Update `docker-compose.yml`:
   ```yaml
   jellyfin:
     # ... other settings ...
     runtime: nvidia
     environment:
       - NVIDIA_VISIBLE_DEVICES=all
   ```

**For Windows:**

On Windows, GPU access for containers depends on Docker Desktop and host driver support. Native Jellyfin running on the host can use DirectX; if you need GPU support from containers on Windows, consult Docker Desktop GPU documentation and the `lscr.io/linuxserver/jellyfin` docs for recommended approaches.

##### Step 2: Restart the Container

```bash
docker compose down
docker compose up -d
```

##### Step 3: Configure Transcoding in Jellyfin

1. Open Jellyfin: http://localhost:8096
2. Go to **Dashboard → Playback → Transcoding**
3. **Hardware acceleration:** Select based on your GPU:

   | GPU Type | Select This Option |
   |----------|-------------------|
   | Intel (Linux) | **VA-API** or **Intel QuickSync (QSV)** |
   | Intel (Windows) | **Intel QuickSync (QSV)** |
   | NVIDIA | **NVIDIA NVENC** |
   | AMD (Linux) | **VA-API** |
   | AMD (Windows) | **AMD AMF** |

4. **Enable hardware decoding** for codecs your GPU supports:
   - ✓ H.264
   - ✓ HEVC (H.265)
   - ✓ MPEG2
   - ✓ VC1
   - ✓ VP9 (Intel 8th gen+, NVIDIA 10xx+)
   - ✓ AV1 (Intel 11th gen+, NVIDIA 30xx+, AMD RX 6000+)

5. **Enable hardware encoding:**
   - ✓ Enable hardware encoding

6. **For Intel VA-API/QSV on Linux:**
   - VA-API Device: `/dev/dri/renderD128`
   - ✓ Enable Low-Power encoding (for Intel 9th gen+)
   - ✓ Enable hardware-accelerated tone mapping (for HDR→SDR)

7. Click **Save**

##### Step 4: Verify Hardware Transcoding is Working

1. Play a video that requires transcoding (e.g., set client to lower quality)
2. Go to **Dashboard → Active Sessions**
3. Look for **(hw)** next to the codec - this indicates hardware acceleration:
   ```
   Video: Direct Stream → H.264 (hw)
   ```

**On Linux, monitor GPU usage:**
```bash
# Intel
sudo apt install intel-gpu-tools
intel_gpu_top

# NVIDIA
nvidia-smi -l 1
```

##### Troubleshooting Hardware Transcoding

| Issue | Solution |
|-------|----------|
| "No hardware acceleration" | Verify `/dev/dri` is mounted in container |
| Permission denied | Add correct group ID to `group_add` |
| Only software transcoding | Check VA-API device path in settings |
| Green/corrupted video | Update GPU drivers; disable tone mapping |
| QSV not available | Use VA-API instead (works on same hardware) |

#### Optional: Create Additional Users

1. Dashboard → Users → Add User
2. Set permissions for each user
3. Users can be imported into Jellyseerr for request management

---

### 6.6 Configure Jellyseerr

1. **Open** http://localhost:5055
2. **Sign in with Jellyfin:**
   - Click "Use your Jellyfin account"
   - Jellyfin URL: `http://jellyfin:8096`
   - Enter your Jellyfin admin username and password
   - Click Sign In

3. **Configure Jellyfin Integration:**
   - After sign-in, you'll be prompted to configure Jellyfin
   - Server: `http://jellyfin:8096`
   - Email (optional): Your email for notifications
   - Sync Libraries: Select your Movies and TV libraries
   - Click "Sync Libraries" to import existing content

4. **Connect to Sonarr:**
   - Settings → Services → Sonarr
   - Click "Add Sonarr Server"
   - Default Server: ✓ Yes
   - Server Name: Sonarr
   - Hostname: `sonarr`
   - Port: `8989`
   - API Key: *(from Sonarr → Settings → General → API Key)*
   - Base URL: (leave empty)
   - Quality Profile: Select your preferred profile
   - Root Folder: `/data/media/tv`
   - Enable Season Folders: ✓ Yes
   - Test and Save

5. **Connect to Radarr:**
   - Settings → Services → Radarr
   - Click "Add Radarr Server"
   - Default Server: ✓ Yes
   - Server Name: Radarr
   - Hostname: `radarr`
   - Port: `7878`
   - API Key: *(from Radarr → Settings → General → API Key)*
   - Base URL: (leave empty)
   - Quality Profile: Select your preferred profile
   - Root Folder: `/data/media/movies`
   - Test and Save

6. **Configure User Permissions (Optional):**
   - Settings → Users
   - Import users from Jellyfin
   - Set request limits and permissions per user

#### Important: Jellyseerr Request Behavior

**Deleting a request in Jellyseerr does NOT remove content from Sonarr/Radarr.** This is by design.

Jellyseerr is a one-way request system:
- It sends requests TO Sonarr/Radarr
- It does NOT manage or remove content FROM Sonarr/Radarr

**To fully remove a show or movie:**

1. **Remove from Sonarr/Radarr first:**
   - Open Sonarr → Series (or Radarr → Movies)
   - Find the item → Click on it
   - Click **Delete**
   - Choose whether to delete files from disk
   
2. **Then clean up Jellyseerr (optional):**
   - Remove the request in Jellyseerr
   - Or go to Settings → Jellyfin → Click **Sync** to refresh status

---

## 7. Connecting Everything Together

### Summary of Connections

At this point, your apps should be connected as follows:

```
Prowlarr ──────► Sonarr (indexers synced via Apps)
    │
    └──────────► Radarr (indexers synced via Apps)

SABnzbd ◄─────── Sonarr (sends downloads)
    │
    └◄────────── Radarr (sends downloads)

Jellyfin ◄────── Watches /data/movies and /data/tvshows

Jellyseerr ────► Sonarr + Radarr (sends requests)
    │
    └──────────► Jellyfin (shows library status)
```

### SABnzbd Categories

Create categories in SABnzbd for organized downloads:

1. Settings → Categories
2. Add category: `tv`
   - Folder/Path: Leave default (will use complete folder)
3. Add category: `movies`
   - Folder/Path: Leave default

### Internal vs External Ports

When configuring connections between containers:

| Connecting From | Connecting To | Use |
|-----------------|---------------|-----|
| Your browser | Any container | `http://localhost:<port>` |
| Container → Container | Another container | `http://<container-name>:<internal-port>` |

Examples:
- Browser to Sonarr: `http://localhost:8989`
- Jellyseerr to Sonarr (inside Docker): `http://sonarr:8989`

---

## 8. Connecting Devices to Jellyfin

### How Jellyfin Connection Works

Unlike Plex, Jellyfin uses **direct IP connection** - you tell devices exactly where your server is. No external account required!

### Finding Your Server IP

**Windows (PowerShell):**
```powershell
ipconfig
```
Look for "IPv4 Address" (e.g., `192.168.1.100`)

**Ubuntu:**
```bash
ip addr
```

### Connecting Devices

#### Smart TVs with Native Apps

| TV Brand | App Availability |
|----------|------------------|
| **LG (webOS)** | Jellyfin app in LG Content Store |
| **Samsung (Tizen)** | Jellyfin app in Samsung Apps |
| **Android TV / Google TV** | Jellyfin app in Play Store |
| **Fire TV** | Jellyfin app in Amazon Appstore |
| **Apple TV** | Jellyfin app in App Store |
| **Roku** | Jellyfin app in Channel Store |

**Setup:**
1. Install Jellyfin from your TV's app store
2. Open the app
3. Enter server address: `http://<your-ip>:8096`
4. Sign in with your Jellyfin username/password

#### Mobile Apps

**Android & iOS:**
1. Install "Jellyfin" from Play Store / App Store (Free!)
2. Add Server: `http://<your-ip>:8096`
3. Sign in

#### Web Browser (Any Device)

Navigate to: `http://<your-ip>:8096`

#### Hisense Vidaa TVs

Vidaa doesn't have a native Jellyfin app. Options:

1. **Vidaa App Installer:** Go to `https://vidaa.flummi.ch` in the TV browser
2. **Streaming Device:** Add a Fire Stick or Chromecast for best experience
3. **DLNA:** Enable DLNA in Jellyfin (Dashboard → DLNA), but playback may be unstable

### Troubleshooting Connection Issues

| Issue | Solution |
|-------|----------|
| Can't connect | Verify server IP is correct |
| Connection refused | Check Windows Firewall allows port 8096 |
| App not finding server | Enter IP manually instead of auto-discovery |
| Buffering | Enable hardware transcoding on server |

**Allow Jellyfin through Windows Firewall:**
```powershell
New-NetFirewallRule -DisplayName "Jellyfin" -Direction Inbound -Protocol TCP -LocalPort 8096 -Action Allow
New-NetFirewallRule -DisplayName "Jellyfin Discovery" -Direction Inbound -Protocol UDP -LocalPort 7359 -Action Allow
```

---

## 9. Remote Access (Optional)

### Direct Port Forwarding

To access Jellyfin from outside your home:

1. Forward port 8096 (TCP) on your router to your server's local IP
2. Access via your public IP: `http://<your-public-ip>:8096`

**Warning:** This exposes your server to the internet. Consider using HTTPS.

### Secure Remote Access with Tailscale (Recommended)

For secure access without opening ports:

1. Install Tailscale on your server and devices
2. Access your apps via Tailscale IP
3. No port forwarding needed
4. Encrypted connection

### Reverse Proxy with HTTPS

For production setups, consider:
- **Nginx Proxy Manager** - Easy GUI for reverse proxy
- **Caddy** - Automatic HTTPS
- **Traefik** - Docker-native reverse proxy

---

## 10. Windows Network Configuration

### Adding Hostname Aliases (Windows Only)

This section describes a Windows-specific PowerShell script (`add-host-alias.ps1`) for adding hostname aliases.


If you want your PC to respond to additional hostnames on the network (e.g., "mediaserver"):

**PowerShell (Run as Administrator):**

```powershell
# Add alias(es) - separate multiple with spaces
$aliases = "mediaserver"

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters" -Name "OptionalNames" -Value $aliases

# Enable the feature
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters" -Name "DisableStrictNameChecking" -Value 1 -Type DWord

# Restart the Server service to apply
Restart-Service lanmanserver -Force
```

Now other devices on your network can reach your PC via `mediaserver` as well as its actual hostname.

### Renaming Your PC (Alternative)

If you prefer to change the actual hostname:

1. Press **Win + I** → System → About
2. Click **Rename this PC**
3. Enter your new hostname
4. Restart

---

## 11. Hardware Transcoding Setup (Linux)

**If you're running this media server on a Linux host**, you can dramatically improve transcoding performance by enabling hardware acceleration. The `docker-compose.yml` is pre-configured for Intel/AMD GPUs.

### Quick Setup (Intel/AMD GPUs)

1. **Find your render group ID:**
   ```bash
   getent group render | cut -d: -f3
   ```

2. **Add it to your `.env` file:**
   ```bash
   RENDER_GROUP_ID=109  # Your value from step 1
   ```

3. **Verify device access:**
   ```bash
   ls -la /dev/dri
   ```

4. **Start containers:**
   ```bash
   docker compose up -d
   ```

5. **Configure Jellyfin:**
   - Dashboard → Playback → Transcoding
   - Hardware acceleration: **Video Acceleration API (VAAPI)**
   - VA-API Device: `/dev/dri/renderD128`

### For NVIDIA GPUs

If you have an NVIDIA GPU, see the detailed guide: **[HARDWARE_TRANSCODING.md](HARDWARE_TRANSCODING.md)**

This includes:
- NVIDIA Container Toolkit installation
- Docker Compose configuration changes
- Performance comparisons and troubleshooting

---

## 12. Troubleshooting

### Docker Networking Issues

**Problem:** Containers can't resolve each other by name (e.g., `http://sabnzbd:8080` fails)

**Solution:** Ensure all containers are on the same network:

1. Check your `docker-compose.yml` includes the explicit network definition (see Section 5)
2. Restart the stack:
   ```powershell
   docker compose down
   docker compose up -d
   ```
3. Verify containers are on the same network:
   ```powershell
   docker network ls
   docker inspect sonarr --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}{{end}}'
   ```

**Test connectivity:**
```bash
docker exec sonarr ping -c 2 sabnzbd
```

### SABnzbd Hostname Verification Failed

**Error:** "Access denied - Hostname verification failed"

**Cause:** SABnzbd blocks connections from unrecognized hostnames

**Solution:**
1. Open SABnzbd at http://localhost:8080
2. Settings → Special → host_whitelist
3. Add: `sabnzbd, localhost`
4. Save and restart: `docker restart sabnzbd`

### Jellyseerr Can't Connect to Jellyfin

**Error:** Connection failed when adding Jellyfin server

**Solutions:**
1. Use container name: `http://jellyfin:8096` (not localhost)
2. Verify Jellyfin is running: `docker ps`
3. Test connectivity: `docker exec jellyseerr ping -c 2 jellyfin`

### Common Issues Quick Reference

| Issue | Solution |
|-------|----------|
| Permission denied | Check PUID/PGID match your user (run `id` on Ubuntu) |
| Container can't reach another | Verify explicit network in docker-compose.yml |
| SABnzbd hostname error | Add container name to host_whitelist |
| Downloads stuck | Check SABnzbd server connection and credentials |
| Media not appearing in Jellyfin | Verify paths match; trigger manual library scan |
| Slow downloads | Increase server connections in SABnzbd |
| Indexer test fails | Verify API key is correct |
| Buffering in Jellyfin | Enable hardware transcoding |

### WSL2 DNS Issues (Windows)

If Docker networking issues persist:

```powershell
wsl --shutdown
```

Then restart Docker Desktop.

---

## 13. Maintenance & Tips

### Useful Commands

```bash
# View logs for a container
docker logs jellyfin

# Follow logs in real-time
docker logs -f jellyfin

# Restart a container
docker restart jellyfin

# Update all containers
docker compose pull
docker compose up -d

# Stop all containers
docker compose down

# View resource usage
docker stats

# Test container connectivity
docker exec sonarr ping -c 2 sabnzbd
```

### Backup Strategy

**What to backup:**
- The entire `config` folder (contains all app settings and databases)

**Windows backup command:**
```powershell
Compress-Archive -Path "D:\MediaServer\config" -DestinationPath "D:\Backups\mediaserver-config-$(Get-Date -Format 'yyyy-MM-dd').zip"
```

**Ubuntu backup command:**
```bash
tar -czvf ~/backups/mediaserver-config-$(date +%Y-%m-%d).tar.gz /opt/mediaserver/config
```

### Performance Tips

1. **SABnzbd:** Enable "Direct Unpack" for faster processing
2. **Jellyfin:** Enable hardware transcoding (free!) for smooth playback
3. **General:** Use SSDs for config folders, HDDs are fine for media
4. **Docker Desktop (Windows):** Allocate adequate RAM in settings

---

## 14. Advanced: Spotweb (Self-Hosted Indexer)

Spotweb is a decentralized, self-hosted Usenet indexer based on the Spotnet protocol. It's an alternative to paid indexers like NZBGeek.

### What is Spotweb?

- **Decentralized:** Content is indexed by the community and stored on Usenet itself
- **Free:** No subscription required (you host it yourself)
- **Self-hosted:** Requires a web server with PHP and MySQL/PostgreSQL

### Spotweb vs Traditional Indexers

| Traditional Indexers | Spotweb |
|----------------------|---------|
| Centralized service | Self-hosted, decentralized |
| Subscription fee | Free |
| Fast for new content | Slightly slower (manual curation) |
| Easy setup | More complex setup |
| Works directly with Prowlarr | Works as Newznab provider |

### When to Consider Spotweb

**Good for:**
- Users who want a free indexing alternative
- Those comfortable with self-hosting
- People wanting full control over their indexer

**Stick with traditional indexers if:**
- You want simple setup
- You're new to Usenet
- You prefer English-language interfaces

### Requirements

- Web server with PHP 7.2+
- MySQL, PostgreSQL, or SQLite database
- Usenet provider access

### Integration with Your Stack

Spotweb can work with Prowlarr as a "Generic Newznab" indexer once configured.

For detailed setup instructions, see: https://github.com/spotweb/spotweb

---

## Quick Reference: API Keys & Ports

| App | Port | API Key Location |
|-----|------|------------------|
| Jellyfin | 8096 | Dashboard → API Keys |
| Jellyseerr | 5055 | Settings → General |
| SABnzbd | 8080 | Settings → General → API Key |
| Sonarr | 8989 | Settings → General → API Key |
| Radarr | 7878 | Settings → General → API Key |
| Prowlarr | 9696 | Settings → General → API Key |

---

## Next Steps

1. ✅ Get Usenet provider subscription
2. ✅ Get 1-2 indexer accounts
3. ✅ Install Docker
4. ✅ Create folder structure
5. ✅ Start Docker Compose stack
6. ✅ Configure SABnzbd hostname whitelist
7. ✅ Configure each application
8. ✅ Connect devices to Jellyfin
9. ✅ Add your first TV show or movie!

---

*Guide created for Windows 11 and Ubuntu LTS. Last updated: January 2025*