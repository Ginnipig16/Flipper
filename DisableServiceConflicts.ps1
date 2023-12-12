# Disable the services
Set-Service -Name 'hns' -StartupType 'Disabled'
Set-Service -Name 'SharedAccess' -StartupType 'Disabled'

# Stop the services
Stop-Service -Name 'hns' -Force
Stop-Service -Name 'SharedAccess' -Force
