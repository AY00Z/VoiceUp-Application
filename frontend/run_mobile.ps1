# Script pour lancer Flutter avec des dimensions mobiles
# Usage: .\run_mobile.ps1 [device]
# Devices: iphone12, iphone14, pixel5, android, custom

param(
    [string]$device = "iphone12"
)

$dimensions = @{
    "iphone12" = "390,844"
    "iphone14" = "390,844"
    "iphone14pro" = "393,852"
    "pixel5" = "393,851"
    "android" = "360,800"
    "galaxy" = "360,800"
    "custom" = "375,812"
}

if ($dimensions.ContainsKey($device)) {
    $size = $dimensions[$device]
    Write-Host "Launching Flutter with $device dimensions: $size" -ForegroundColor Green
    flutter run -d chrome --web-browser-flag "--window-size=$size"
} else {
    Write-Host "Unknown device: $device" -ForegroundColor Red
    Write-Host "Available devices: iphone12, iphone14, iphone14pro, pixel5, android, galaxy, custom" -ForegroundColor Yellow
    Write-Host "Usage: .\run_mobile.ps1 [device]" -ForegroundColor Yellow
}


