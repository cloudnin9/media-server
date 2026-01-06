# Request admin elevation if not already running as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host "Requesting administrator privileges..."
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit 0
}

# Add alias(es) - separate multiple with spaces
$aliases = "mediaserver naingwinlpt"

Write-Output "Adding host aliases: $aliases"

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters" -Name "OptionalNames" -Value $aliases

# Enable the feature
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters" -Name "DisableStrictNameChecking" -Value 1 -Type DWord

# Restart the Server service to apply
Restart-Service lanmanserver -Force
Restart-Service lanmanworkstation -Force
Get-NetAdapter | Restart-NetAdapter