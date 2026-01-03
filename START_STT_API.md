# 🚀 Comment démarrer STT_API

## Problème
Les logs montrent : `Error calling STT_API: ClientException: Failed to fetch`

Cela signifie que STT_API n'est pas démarré.

## Solution : Démarrer STT_API

### Étape 1 : Ouvrir un nouveau terminal

### Étape 2 : Naviguer vers le dossier STT_API

```bash
cd STT_API/VoiceUP/api/VoiceUP/STT_API
```

### Étape 3 : Démarrer STT_API

```bash
python app.py
```

Vous devriez voir quelque chose comme :
```
Loading Whisper model 'tiny' on device=cpu compute_type=None
 * Running on http://0.0.0.0:5001
```

### Étape 4 : Vérifier que ça fonctionne

Dans un autre terminal :
```bash
curl http://127.0.0.1:5001/health
```

Résultat attendu :
```json
{"status": "ok", "model": "tiny", "device": "cpu"}
```

## ⚠️ Important

**STT_API doit être démarré AVANT d'envoyer des messages vocaux !**

Si STT_API n'est pas démarré :
- Les messages vocaux seront envoyés SANS transcription
- Vous verrez l'erreur : `STT_API error (continuing without transcription)`

## Ordre de démarrage recommandé

1. **Démarrer STT_API** (port 5001)
   ```bash
   cd STT_API/VoiceUP/api/VoiceUP/STT_API
   python app.py
   ```

2. **Démarrer le Backend** (port 5000)
   ```bash
   cd backend/VoiceUP/VoiceUP_Backend
   python app.py
   ```

3. **Lancer l'application Flutter**

## Vérification

Après avoir démarré STT_API, envoyez un nouveau message vocal. Vous devriez voir dans les logs Flutter :

```
Calling STT_API for transcription...
Sending audio to STT_API: [nombre] bytes
STT transcription: [texte transcrit] (confidence: [score])
```

Et dans les logs du backend :

```
[DEBUG] Transcription data received: {'text': '...', 'confidence': ...}
[DEBUG] Transcription text: ...
[DEBUG] Transcription added to database for message ...
```

