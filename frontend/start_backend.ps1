# Script pour démarrer le backend Flask
# VoiceUP Project

$backendPath = "..\backend\VoiceUP\VoiceUP_Backend"

Write-Host "🚀 Démarrage du Backend Flask..." -ForegroundColor Cyan
Write-Host ""

if (Test-Path $backendPath) {
    Set-Location $backendPath
    
    # Vérifier si .env existe
    if (-not (Test-Path ".env")) {
        Write-Host "❌ ERREUR: Le fichier .env n'existe pas!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Veuillez créer un fichier .env avec:" -ForegroundColor Yellow
        Write-Host "DATABASE_URL=postgresql://postgres:VOTRE_MDP@localhost:5432/voiceup_db" -ForegroundColor White
        Write-Host "UPLOAD_FOLDER=uploads" -ForegroundColor White
        Write-Host ""
        exit 1
    }
    
    Write-Host "✅ Fichier .env trouvé" -ForegroundColor Green
    Write-Host "🔄 Démarrage du serveur Flask sur http://127.0.0.1:5000..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Appuyez sur Ctrl+C pour arrêter le serveur" -ForegroundColor Yellow
    Write-Host ""
    
    python app.py
} else {
    Write-Host "❌ Dossier backend introuvable: $backendPath" -ForegroundColor Red
    exit 1
}


