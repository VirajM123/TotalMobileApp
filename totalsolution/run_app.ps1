# Flutter app runner script
Write-Host "Starting Flutter application..." -ForegroundColor Green

# Check for available devices
Write-Host "`nChecking available devices..." -ForegroundColor Yellow
flutter devices

# Run the app
Write-Host "`nRunning Flutter app..." -ForegroundColor Yellow
flutter run -d chrome

# Keep window open
Write-Host "`nPress any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

