# Script pour démarrer le frontend Flutter
# VoiceUP Project

Write-Host "📱 Démarrage du Frontend Flutter..." -ForegroundColor Cyan
Write-Host ""

# Vérifier que Flutter est installé
try {
    flutter --version | Out-Null
} catch {
    Write-Host "❌ Flutter n'est pas installé ou pas dans PATH" -ForegroundColor Red
    exit 1
}

# Vérifier que nous sommes dans le bon dossier
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "❌ Erreur: Ce script doit être exécuté depuis le dossier frontend" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Flutter trouvé" -ForegroundColor Green
Write-Host ""

# Vérifier les dépendances
if (-not (Test-Path "pubspec.lock")) {
    Write-Host "📦 Installation des dépendances..." -ForegroundColor Yellow
    flutter pub get
    Write-Host ""
}

# Demander la plateforme
Write-Host "Choisissez la plateforme:" -ForegroundColor Yellow
Write-Host "1. Web (Edge)" -ForegroundColor White
Write-Host "2. Web (Chrome)" -ForegroundColor White
Write-Host "3. Windows Desktop" -ForegroundColor White
Write-Host "4. Android (si device/émulateur connecté)" -ForegroundColor White
Write-Host ""
$choice = Read-Host "Votre choix (1-4)"

$device = switch ($choice) {
    "1" { "edge" }
    "2" { "chrome" }
    "3" { "windows" }
    "4" { "android" }
    default { 
        Write-Host "Choix invalide, utilisation de Edge par défaut" -ForegroundColor Yellow
        "edge"
    }
}

Write-Host ""
Write-Host "🚀 Lancement de l'application sur $device..." -ForegroundColor Yellow
Write-Host ""
Write-Host "⚠️  Assurez-vous que le backend Flask est en cours d'exécution!" -ForegroundColor Yellow
Write-Host "   Backend URL: http://127.0.0.1:5000" -ForegroundColor Yellow
Write-Host ""

flutter run -d $device


