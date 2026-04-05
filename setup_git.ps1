# Set location to totalsolution
Set-Location "L:\Total App\totalsolution"

# Check if git is already initialized
if (-not (Test-Path ".git")) {
    Write-Host "Initializing git repository..."
    & git init
} else {
    Write-Host "Git repository already initialized"
}

# Configure git user (replace with your name and email)
& git config user.email "viraj@example.com"
& git config user.name "Viraj"

# Add all files
Write-Host "Adding files to git..."
& git add .

# Check status
& git status

