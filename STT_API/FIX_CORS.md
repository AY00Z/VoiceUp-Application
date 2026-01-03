# 🔧 Fix CORS pour STT_API

## Problème
Les logs montrent :
```
Error calling STT_API: ClientException: Failed to fetch, uri=http://127.0.0.1:5001/transcribe
```

C'est un problème de **CORS** (Cross-Origin Resource Sharing). Le navigateur bloque les requêtes depuis l'app Flutter web vers STT_API.

## Solution

### 1. Installer flask-cors

```bash
cd STT_API/VoiceUP/api/VoiceUP/STT_API
pip install flask-cors
```

### 2. Redémarrer STT_API

Arrêtez STT_API (Ctrl+C) et redémarrez-le :

```bash
python app.py
```

Vous devriez voir :
```
Loading Whisper model 'tiny' on device=cpu compute_type=None
 * Running on http://0.0.0.0:5001
```

### 3. Tester

Envoyez un nouveau message vocal depuis l'app Flutter. Vous devriez maintenant voir dans les logs :

```
[DEBUG] Calling STT_API for transcription...
Sending audio to STT_API: 587072 bytes
STT_API transcription result: [texte transcrit]
[DEBUG] STT transcription: [texte] (confidence: 0.95)
```

## Vérification

Vérifiez que CORS est activé en testant avec curl :

```bash
curl -X OPTIONS http://127.0.0.1:5001/transcribe \
  -H "Origin: http://localhost:58996" \
  -H "Access-Control-Request-Method: POST" \
  -v
```

Vous devriez voir des headers CORS dans la réponse.

## Note

J'ai déjà modifié `app.py` pour activer CORS. Il suffit d'installer `flask-cors` et de redémarrer STT_API.

