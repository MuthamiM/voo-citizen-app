$ErrorActionPreference = "SilentlyContinue"

Write-Host "🔍 Searching for Flutter installation..." -ForegroundColor Cyan

# Common installation paths
$possiblePaths = @(
    "C:\flutter",
    "C:\src\flutter",
    "$env:USERPROFILE\flutter",
    "$env:USERPROFILE\Downloads\flutter",
    "C:\tools\flutter"
)

$flutterPath = $null

foreach ($path in $possiblePaths) {
    if (Test-Path "$path\bin\flutter.bat") {
        $flutterPath = $path
        break
    }
}

if (-not $flutterPath) {
    Write-Host "⚠️ Flutter not found in common locations." -ForegroundColor Yellow
    $flutterPath = Read-Host "Please enter the full path to your extracted 'flutter' folder (e.g., C:\flutter)"
}

if (Test-Path "$flutterPath\bin\flutter.bat") {
    Write-Host "✅ Found Flutter at: $flutterPath" -ForegroundColor Green
    
    $binPath = "$flutterPath\bin"
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    
    if ($currentPath -notlike "*$binPath*") {
        Write-Host "⚙️ Adding Flutter to User PATH..." -ForegroundColor Cyan
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$binPath", "User")
        Write-Host "✅ Flutter added to PATH! Please restart your terminal." -ForegroundColor Green
    } else {
        Write-Host "✅ Flutter is already in your PATH." -ForegroundColor Green
    }
    
    Write-Host "`n🎉 Setup complete! You can now run:" -ForegroundColor White
    Write-Host "   cd mobile" -ForegroundColor Gray
    Write-Host "   flutter doctor" -ForegroundColor Gray
    Write-Host "   flutter run" -ForegroundColor Gray
} else {
    Write-Host "❌ Could not verify Flutter installation at: $flutterPath" -ForegroundColor Red
    Write-Host "Please check the path and try again."
}
