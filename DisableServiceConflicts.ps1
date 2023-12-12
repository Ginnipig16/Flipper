# Disable the services
Set-Service -Name 'hns' -StartupType 'Disabled'
Set-Service -Name 'SharedAccess' -StartupType 'Disabled'
Write-Host "Set Host Network Service to DISABLED" -ForegroundColor Green
Write-Host "Set Internet connection sharing to DISABLED" -ForegroundColor Green

# Stop the services
Stop-Service -Name 'hns' -Force
Stop-Service -Name 'SharedAccess' -Force
Write-Host "Stopping the services complete" -ForegroundColor Green
