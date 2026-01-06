# Create all directories (adjust D: to your preferred drive)
$base = "C:\MediaServer"

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

