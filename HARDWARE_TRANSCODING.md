# Hardware Transcoding Setup for Linux Hosts

This guide explains how to enable hardware-accelerated transcoding in Jellyfin when running on Linux hosts.

## Overview

Hardware transcoding dramatically reduces CPU usage and improves performance by offloading video encoding/decoding to dedicated GPU hardware. This setup supports:

- **Intel QuickSync** (integrated Intel GPUs)
- **AMD VAAPI** (AMD GPUs)
- **NVIDIA NVENC/NVDEC** (NVIDIA GPUs)

## Current Configuration

The `docker-compose.yml` is **pre-configured for Intel/AMD GPUs** by default. If you have an NVIDIA GPU, follow the NVIDIA-specific instructions below.

### Intel/AMD GPUs (Default - Already Enabled)

The configuration includes:

```yaml
devices:
  - /dev/dri:/dev/dri
group_add:
  - "${RENDER_GROUP_ID}"
```

**Setup Steps:**

1. Find your render group ID:
   ```bash
   getent group render | cut -d: -f3
   ```

2. Add it to your `.env` file:
   ```bash
   RENDER_GROUP_ID=109  # Your value may differ
   ```

3. Verify `/dev/dri` exists:
   ```bash
   ls -la /dev/dri
   ```
   You should see devices like `card0`, `renderD128`, etc.

4. Start the containers:
   ```bash
   docker compose up -d
   ```

5. In Jellyfin, go to **Dashboard → Playback → Transcoding**:
   - Hardware acceleration: **Video Acceleration API (VAAPI)**
   - VA-API Device: `/dev/dri/renderD128`
   - Enable hardware decoding for your media types

### NVIDIA GPUs

**Prerequisites:**

1. Install NVIDIA Container Toolkit:
   ```bash
   # Ubuntu/Debian
   distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
   curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
   curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
     sudo tee /etc/apt/sources.list.d/nvidia-docker.list

   sudo apt-get update
   sudo apt-get install -y nvidia-container-toolkit
   sudo systemctl restart docker
   ```

2. Verify installation:
   ```bash
   docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
   ```

**Configuration Changes:**

1. Edit `docker-compose.yml` in the jellyfin service:

   **Comment out** the Intel/AMD section:
   ```yaml
   # devices:
   #   - /dev/dri:/dev/dri
   # group_add:
   #   - "${RENDER_GROUP_ID}"
   ```

   **Uncomment** the NVIDIA section:
   ```yaml
   runtime: nvidia
   environment:
     - NVIDIA_VISIBLE_DEVICES=all
   deploy:
     resources:
       reservations:
         devices:
           - driver: nvidia
             count: 1
             capabilities: [gpu]
   ```

2. Restart containers:
   ```bash
   docker compose down
   docker compose up -d
   ```

3. In Jellyfin, go to **Dashboard → Playback → Transcoding**:
   - Hardware acceleration: **NVIDIA NVENC**
   - Enable hardware decoding for your media types

## Verifying Hardware Transcoding

### Method 1: Check Jellyfin Logs
```bash
docker logs jellyfin
```
Look for messages like:
- `[vaapi]` or `[qsv]` for Intel
- `[nvdec]` or `[nvenc]` for NVIDIA

### Method 2: Monitor GPU Usage

**Intel/AMD:**
```bash
intel_gpu_top  # Install: sudo apt install intel-gpu-tools
```

**NVIDIA:**
```bash
nvidia-smi -l 1  # Live monitoring
```

### Method 3: During Playback

1. Start playing a video in Jellyfin
2. Go to **Dashboard → Playback**
3. Look for active transcoding sessions
4. Check if "HW" indicator appears

## Troubleshooting

### Intel/AMD: Permission Denied for /dev/dri

```bash
# Check current permissions
ls -la /dev/dri

# Add your user to render and video groups
sudo usermod -aG render,video $USER
sudo usermod -aG render,video $(id -u):$(id -g)  # For containers

# Restart Docker
sudo systemctl restart docker
```

### NVIDIA: GPU Not Detected

```bash
# Verify NVIDIA driver
nvidia-smi

# Check Docker can access GPU
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

# Restart Docker daemon
sudo systemctl restart docker
```

### Transcoding Still Using CPU

1. Verify hardware acceleration is enabled in Jellyfin settings
2. Check codec compatibility (not all codecs support hardware acceleration)
3. Review Jellyfin logs for error messages
4. Ensure proper device permissions

## Performance Comparison

Typical performance gains with hardware transcoding:

| Task | CPU Only | With HW Transcoding |
|------|----------|---------------------|
| 4K → 1080p H.264 | ~80-100% CPU | ~5-15% CPU |
| 1080p → 720p H.264 | ~30-50% CPU | ~2-5% CPU |
| HEVC encoding | ~100% CPU | ~10-20% CPU |

## Supported Codecs

### Intel QuickSync (7th gen+)
- H.264 (AVC)
- HEVC (H.265)
- VP9 (9th gen+)
- AV1 (11th gen+)

### AMD VAAPI
- H.264 (AVC)
- HEVC (H.265)
- VP9

### NVIDIA NVENC
- H.264 (AVC)
- HEVC (H.265)
- AV1 (RTX 40 series+)

## Additional Resources

- [Jellyfin Hardware Acceleration Guide](https://jellyfin.org/docs/general/administration/hardware-acceleration/)
- [Intel QuickSync Requirements](https://github.com/intel/media-driver)
- [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker)
