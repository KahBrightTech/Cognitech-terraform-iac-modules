<powershell>

# -------------------------------------------
# Check if SSM Agent is installed; if not, install it
# -------------------------------------------
$ssmPath = "C:\Program Files\Amazon\SSM\amazon-ssm-agent.exe"
if (-Not (Test-Path $ssmPath)) {
    Write-Output "SSM Agent is not installed. Installing..."
    Invoke-WebRequest -Uri "https://s3.amazonaws.com/amazon-ssm-${env:PROCESSOR_ARCHITECTURE}/latest/windows_amd64/AmazonSSMAgentSetup.exe" -OutFile "$env:TEMP\AmazonSSMAgentSetup.exe"
    Start-Process -FilePath "$env:TEMP\AmazonSSMAgentSetup.exe" -ArgumentList "/quiet" -Wait
    Write-Output "SSM Agent installed successfully."
    Start-Service AmazonSSMAgent
    Set-Service -Name AmazonSSMAgent -StartupType Automatic
    Write-Output "SSM Agent service started and enabled."
}
else {
    Write-Output "SSM Agent is already installed."
}

# -------------------------------------------
# Check if AWS CLI is installed; if not, install it
# -------------------------------------------
if (-Not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Output "AWS CLI is not installed. Installing..."
    $installerPath = "$env:TEMP\AWSCLIV2.msi"
    Invoke-WebRequest "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile $installerPath
    Start-Process msiexec.exe -Wait -ArgumentList "/i `"$installerPath`" /quiet"
    Write-Output "AWS CLI installed successfully."
}
else {
    Write-Output "AWS CLI is already installed."
}

# -------------------------------------------
# Set time zone to Eastern Standard Time
# -------------------------------------------
tzutil /s "Eastern Standard Time"
Write-Output "Time zone set to Eastern Standard Time."

# -------------------------------------------
# Check if Docker is installed; if not, install it
# -------------------------------------------
if (-Not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Output "Docker is not installed. Installing..."
    Invoke-WebRequest -UseBasicParsing -Uri "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe" -OutFile "$env:TEMP\DockerInstaller.exe"
    Start-Process -FilePath "$env:TEMP\DockerInstaller.exe" -ArgumentList "--quiet", "--accept-license" -Wait
    Write-Output "Docker installed successfully."

    # Optionally start Docker if required
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    Write-Output "Docker started."
}
else {
    Write-Output "Docker is already installed."
}

</powershell>
