Set-Location "L:\Total App\totalsolution"

# Create initial commit
Write-Host "Creating initial commit..."
& git commit -m "Initial commit - Total Solution Flutter App"

# Create GitHub repository and push
Write-Host "Creating GitHub repository..."
& "C:\Program Files\GitHub CLI\gh.exe" repo create totalsolution --public --source=. --push --description "Total Solution - Flutter Salesman/Distributor App"

