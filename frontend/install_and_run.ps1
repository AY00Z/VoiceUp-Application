# Script d'installation et démarrage - Backend & Frontend
# VoiceUP Project

Write-Host "🚀 VoiceUP - Installation et Démarrage" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Chemins
$backendPath = "..\backend\VoiceUP\VoiceUP_Backend"
$frontendPath = Get-Location

# Fonction pour vérifier si Python est installé
function Test-Python {
    try {
        $pythonVersion = python --version 2>&1
        Write-Host "✅ Python trouvé: $pythonVersion" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Python n'est pas installé ou pas dans PATH" -ForegroundColor Red
        return $false
    }
}

# Fonction pour vérifier si Flutter est installé
function Test-Flutter {
    try {
        $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
        Write-Host "✅ Flutter trouvé: $flutterVersion" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Flutter n'est pas installé ou pas dans PATH" -ForegroundColor Red
        return $false
    }
}

# Vérifier les prérequis
Write-Host "📋 Vérification des prérequis..." -ForegroundColor Yellow
$pythonOk = Test-Python
$flutterOk = Test-Flutter

if (-not $pythonOk -or -not $flutterOk) {
    Write-Host ""
    Write-Host "❌ Prérequis manquants. Veuillez installer Python et/ou Flutter." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "1️⃣  INSTALLATION DU BACKEND" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Aller dans le dossier backend
if (Test-Path $backendPath) {
    Push-Location $backendPath
    
    Write-Host "📦 Installation des dépendances Python..." -ForegroundColor Yellow
    pip install -r requirements.txt
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Dépendances backend installées avec succès!" -ForegroundColor Green
    } else {
        Write-Host "❌ Erreur lors de l'installation des dépendances backend" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    # Vérifier si .env existe
    if (-not (Test-Path ".env")) {
        Write-Host ""
        Write-Host "⚠️  ATTENTION: Le fichier .env n'existe pas!" -ForegroundColor Yellow
        Write-Host "   Veuillez créer un fichier .env avec:" -ForegroundColor Yellow
        Write-Host "   DATABASE_URL=postgresql://postgres:VOTRE_MDP@localhost:5432/voiceup_db" -ForegroundColor Yellow
        Write-Host "   UPLOAD_FOLDER=uploads" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   Appuyez sur Entrée après avoir créé le fichier .env..." -ForegroundColor Yellow
        Read-Host
    }
    
    Pop-Location
} else {
    Write-Host "❌ Dossier backend introuvable: $backendPath" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "2️⃣  INSTALLATION DU FRONTEND" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Revenir au dossier frontend
Set-Location $frontendPath

Write-Host "📦 Installation des dépendances Flutter..." -ForegroundColor Yellow
flutter pub get

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Dépendances frontend installées avec succès!" -ForegroundColor Green
} else {
    Write-Host "❌ Erreur lors de l'installation des dépendances frontend" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "✅ INSTALLATION TERMINÉE!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 PROCHAINES ÉTAPES:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. BACKEND:" -ForegroundColor Cyan
Write-Host "   cd ..\backend\VoiceUP\VoiceUP_Backend" -ForegroundColor White
Write-Host "   python app.py" -ForegroundColor White
Write-Host ""
Write-Host "2. Dans un NOUVEAU terminal, peupler la DB:" -ForegroundColor Cyan
Write-Host "   cd ..\backend\VoiceUP\VoiceUP_Backend" -ForegroundColor White
Write-Host "   python seed.py" -ForegroundColor White
Write-Host ""
Write-Host "3. FRONTEND:" -ForegroundColor Cyan
Write-Host "   cd frontend" -ForegroundColor White
Write-Host "   flutter run -d edge" -ForegroundColor White
Write-Host ""
Write-Host "📖 Voir SETUP_GUIDE.md pour plus de détails" -ForegroundColor Yellow
Write-Host ""


