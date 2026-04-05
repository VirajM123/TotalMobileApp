Set-Location "L:\Total App\totalsolution"

# Create GitHub repository and push
Write-Host "Creating GitHub repository..."
& "C:\Program Files\GitHub CLI\gh.exe" repo create totalsolution --public --source=. --push --description "Total Solution - Flutter Salesman/Distributor App"

