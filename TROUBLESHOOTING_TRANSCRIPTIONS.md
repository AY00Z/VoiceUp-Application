# 🔍 Dépannage : Pourquoi les transcriptions ne sont pas sauvegardées

## Problème
Aucune transcription n'est sauvegardée dans la base de données, même pour les messages récents.

## Étapes de diagnostic

### 1. Vérifier que STT_API est démarré

```bash
# Terminal 1 : Démarrer STT_API
cd STT_API/VoiceUP/api/VoiceUP/STT_API
python app.py
```

Vérifier qu'il répond :
```bash
curl http://127.0.0.1:5001/health
```

**Résultat attendu :**
```json
{"status": "ok", "model": "tiny", "device": "cpu"}
```

### 2. Vérifier les logs du frontend (Flutter)

Quand vous envoyez un message vocal, vous devriez voir dans la console Flutter :

```
Calling STT_API for transcription...
STT transcription: [texte transcrit] (confidence: 0.95)
```

**Si vous voyez :**
```
STT_API error (continuing without transcription): ...
```

Cela signifie que STT_API n'est pas accessible ou a échoué.

### 3. Vérifier les logs du backend

Quand vous envoyez un message vocal, vous devriez voir dans les logs du backend :

```
[DEBUG] Transcription data received: {'text': '...', 'confidence': ...}
[DEBUG] Transcription text: ...
[DEBUG] Transcription added to database for message ...
```

**Si vous voyez :**
```
[DEBUG] Warning: No transcription data provided or invalid format
```

Cela signifie que le frontend n'envoie pas la transcription.

### 4. Vérifier le format des données envoyées

Le frontend doit envoyer :
```json
{
  "type": "AUDIO",
  "encryptedPayloadUrl": "...",
  "iv": "...",
  "transcription": {
    "text": "texte transcrit",
    "confidence": 0.95
  }
}
```

## Solutions

### Solution 1 : STT_API n'est pas démarré

**Symptôme :** Erreur dans les logs frontend : "STT_API error"

**Solution :**
```bash
cd STT_API/VoiceUP/api/VoiceUP/STT_API
python app.py
```

### Solution 2 : STT_API n'est pas accessible

**Symptôme :** Timeout ou erreur de connexion

**Vérifier :**
- STT_API est sur le port 5001
- Pas de firewall qui bloque
- URL correcte dans `stt_service.dart` : `http://127.0.0.1:5001`

### Solution 3 : La transcription n'est pas envoyée au backend

**Symptôme :** Pas de logs `[DEBUG] Transcription data received` dans le backend

**Vérifier :**
1. Les logs frontend montrent que STT_API a réussi
2. Le code dans `chat_page.dart` envoie bien `transcriptionText` et `transcriptionConfidence`
3. Le code dans `messages_service.dart` formate correctement la transcription

### Solution 4 : Erreur lors de la sauvegarde

**Symptôme :** Logs montrent que la transcription est reçue mais pas sauvegardée

**Vérifier :**
- Les logs du backend montrent une erreur SQL
- La table `transcription` existe dans la base de données
- Les permissions de la base de données

## Test complet

1. **Démarrer STT_API :**
   ```bash
   cd STT_API/VoiceUP/api/VoiceUP/STT_API
   python app.py
   ```

2. **Démarrer le backend :**
   ```bash
   cd backend/VoiceUP/VoiceUP_Backend
   python app.py
   ```

3. **Envoyer un nouveau message vocal depuis l'app Flutter**

4. **Vérifier les logs :**
   - Frontend : "Calling STT_API..." et "STT transcription: ..."
   - Backend : "[DEBUG] Transcription data received..."

5. **Vérifier la base de données :**
   ```bash
   python check_db.py
   ```

## Commandes utiles

### Vérifier si STT_API répond
```bash
curl http://127.0.0.1:5001/health
```

### Tester STT_API directement
```bash
cd STT_API/VoiceUP/api/VoiceUP/STT_API
python client_post.py /path/to/audio.wav
```

### Vérifier les messages récents
```bash
cd backend/VoiceUP/VoiceUP_Backend
python quick_check.py
```

### Diagnostic complet
```bash
cd backend/VoiceUP/VoiceUP_Backend
python debug_transcription.py
```

