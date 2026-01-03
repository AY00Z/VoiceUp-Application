# Script pour peupler la base de données avec des données de test
# VoiceUP Project

$backendPath = "..\backend\VoiceUP\VoiceUP_Backend"

Write-Host "🌱 Peuplement de la base de données..." -ForegroundColor Cyan
Write-Host ""

if (Test-Path $backendPath) {
    Set-Location $backendPath
    
    if (-not (Test-Path ".env")) {
        Write-Host "❌ ERREUR: Le fichier .env n'existe pas!" -ForegroundColor Red
        Write-Host "   Veuillez créer le fichier .env d'abord." -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "🔄 Exécution du script seed.py..." -ForegroundColor Yellow
    Write-Host ""
    
    python seed.py
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Base de données peuplée avec succès!" -ForegroundColor Green
        Write-Host "   5 contacts fictifs ont été ajoutés." -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "❌ Erreur lors du peuplement de la base de données" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Dossier backend introuvable: $backendPath" -ForegroundColor Red
    exit 1
}


