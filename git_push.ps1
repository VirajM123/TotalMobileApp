Set-Location "L:\Total App\totalsolution"

# Add remote with credentials
Write-Host "Adding remote with GitHub credentials..."
& git remote add origin https://VirajM123:Viraj%40937092@github.com/VirajM123/totalsolution.git

# Push to GitHub
Write-Host "Pushing to GitHub..."
& git push -u origin master

