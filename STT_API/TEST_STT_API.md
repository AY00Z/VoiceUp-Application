# 🧪 Guide de Test de STT_API

## Méthode 1 : Utiliser le script Python (Recommandé)

### Prérequis
1. Assurez-vous que STT_API est démarré :
   ```bash
   cd STT_API/VoiceUP/api/VoiceUP/STT_API
   python app.py
   ```
   L'API devrait démarrer sur `http://127.0.0.1:5001`

### Tester avec un fichier audio

```bash
cd STT_API/VoiceUP/api/VoiceUP/STT_API
python client_post.py /path/to/your/audio.wav
```

**Exemple :**
```bash
python client_post.py audio_files/file.wav
```

### Résultat attendu :
```json
{
  "transcription": "Hello, this is a test transcription.",
  "confidence": 0.95,
  "segments": [
    {
      "start": 0.0,
      "end": 2.5,
      "text": "Hello, this is a test transcription."
    }
  ],
  "info": {
    "language": "en",
    "language_probability": 0.99
  }
}
```

---

## Méthode 2 : Utiliser curl

### 1. Vérifier que l'API fonctionne
```bash
curl http://127.0.0.1:5001/health
```

**Résultat attendu :**
```json
{
  "status": "ok",
  "model": "tiny",
  "device": "cpu"
}
```

### 2. Transcrire un fichier audio
```bash
curl -X POST http://127.0.0.1:5001/transcribe \
  -F "file=@/path/to/your/audio.wav"
```

**Exemple avec un fichier local :**
```bash
curl -X POST http://127.0.0.1:5001/transcribe \
  -F "file=@audio.wav"
```

---

## Méthode 3 : Utiliser Python interactif

```python
import requests

# Test health endpoint
response = requests.get("http://127.0.0.1:5001/health")
print("Health:", response.json())

# Test transcription
with open("audio.wav", "rb") as f:
    files = {"file": ("audio.wav", f, "audio/wav")}
    response = requests.post("http://127.0.0.1:5001/transcribe", files=files)
    result = response.json()
    print("\nTranscription:", result["transcription"])
    print("Confidence:", result.get("confidence"))
```

---

## Méthode 4 : Tester depuis le navigateur (POST uniquement)

Vous pouvez utiliser un outil comme **Postman** ou **Insomnia** :

1. **URL** : `http://127.0.0.1:5001/transcribe`
2. **Method** : `POST`
3. **Body** : `form-data`
4. **Key** : `file` (type: File)
5. **Value** : Sélectionnez votre fichier audio

---

## Formats audio supportés

- ✅ `.wav`
- ✅ `.mp3`
- ✅ `.m4a`
- ✅ `.flac`
- ✅ `.ogg`
- ✅ `.webm`

---

## Dépannage

### Erreur : "Connection refused"
- Vérifiez que STT_API est démarré sur le port 5001
- Vérifiez avec : `curl http://127.0.0.1:5001/health`

### Erreur : "Model not found"
- Le modèle Whisper sera téléchargé automatiquement au premier démarrage
- Cela peut prendre quelques minutes selon votre connexion

### Erreur : "Unsupported file extension"
- Vérifiez que votre fichier a une extension supportée
- Vérifiez que le fichier est bien un fichier audio valide

### Transcription vide ou incorrecte
- Vérifiez que l'audio contient bien de la parole
- Vérifiez la qualité audio (bruit de fond, volume)
- Essayez avec un modèle plus grand (`small` ou `medium`)

---

## Exemple complet

```bash
# 1. Démarrer STT_API
cd STT_API/VoiceUP/api/VoiceUP/STT_API
python app.py

# Dans un autre terminal :

# 2. Vérifier la santé
curl http://127.0.0.1:5001/health

# 3. Transcrire un fichier
cd STT_API/VoiceUP/api/VoiceUP/STT_API
python client_post.py audio_files/file.wav
```

---

## Notes

- Le premier démarrage peut être lent (téléchargement du modèle)
- La transcription peut prendre quelques secondes selon la longueur de l'audio
- Le modèle `tiny` est rapide mais moins précis que `small` ou `medium`

