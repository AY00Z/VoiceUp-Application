# STT_API - Speech-to-Text Transcription Service

## 🎯 Qu'est-ce que cette API ?

**STT_API** est un service de transcription vocale (Speech-to-Text) qui utilise le modèle **Whisper** d'OpenAI pour convertir des fichiers audio en texte.

### Fonctionnalités :

✅ **Transcription audio** : Convertit WAV, MP3, M4A, FLAC, OGG, WebM en texte  
✅ **Pré-traitement automatique** : Convertit l'audio en 16kHz mono WAV  
✅ **Score de confiance** : Retourne un score de confiance (0.0 à 1.0)  
✅ **Segments avec timestamps** : Retourne la transcription segmentée avec début/fin  
✅ **Détection de langue** : Détecte automatiquement la langue parlée  

## 📁 Structure

```
STT_API/
└── VoiceUP/
    └── api/
        └── VoiceUP/
            └── STT_API/
                ├── app.py              # API Flask principale
                ├── client_post.py      # Script de test
                ├── export_to_onnx.py   # Export modèle ONNX (optionnel)
                ├── requirements.txt    # Dépendances Python
                └── utils/
                    └── audio.py        # Utilitaires audio
```

## 🚀 Installation Rapide

### 1. Installer les dépendances

```bash
cd STT_API/VoiceUP/api/VoiceUP/STT_API
pip install -r requirements.txt
```

**Note** : Le premier démarrage téléchargera automatiquement le modèle Whisper (peut prendre quelques minutes).

### 2. Lancer l'API

```bash
python app.py
```

L'API démarre sur : **http://127.0.0.1:5000**

## 📡 Endpoints

### GET /health
Vérifier que l'API fonctionne.

**Réponse :**
```json
{
  "status": "ok",
  "model": "tiny",
  "device": "cpu"
}
```

### POST /transcribe
Transcrire un fichier audio.

**Request :**
- Method: `POST`
- Content-Type: `multipart/form-data`
- Field: `file` (fichier audio)
- Formats: `.wav`, `.mp3`, `.m4a`, `.flac`, `.ogg`, `.webm`
- Taille max: 50 MB

**Exemple avec curl :**
```bash
curl -X POST http://127.0.0.1:5000/transcribe \
  -F "file=@/path/to/audio.wav"
```

**Réponse :**
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

## ⚙️ Configuration

### Variables d'environnement (optionnel) :

```bash
# Modèle Whisper (tiny, small, medium, large-v3)
export WHISPER_MODEL=tiny

# Device (cpu ou cuda pour GPU)
export WHISPER_DEVICE=cpu

# Type de calcul (float16 pour GPU)
export WHISPER_COMPUTE=float16
```

### Modèles disponibles :

| Modèle | Taille | Vitesse | Précision | RAM |
|--------|--------|---------|-----------|-----|
| `tiny` | 39 MB | ⚡⚡⚡ | ⭐⭐ | ~1 GB |
| `small` | 244 MB | ⚡⚡ | ⭐⭐⭐ | ~2 GB |
| `medium` | 769 MB | ⚡ | ⭐⭐⭐⭐ | ~5 GB |
| `large-v3` | 1550 MB | 🐌 | ⭐⭐⭐⭐⭐ | ~10 GB |

**Recommandation :**
- **Développement** : `tiny` (rapide)
- **Production** : `small` ou `medium` (bon compromis)

## 🧪 Test

### Test rapide :

```bash
# 1. Vérifier que l'API fonctionne
curl http://127.0.0.1:5000/health

# 2. Transcrire un fichier
python client_post.py /path/to/audio.wav
```

## 🔌 Intégration avec votre App Flutter

Voir `STT_API_DOCUMENTATION.md` pour les détails complets d'intégration.

**Exemple simple :**
```dart
Future<Map<String, dynamic>> transcribeAudio(String audioPath) async {
  final uri = Uri.parse('http://127.0.0.1:5000/transcribe');
  final request = http.MultipartRequest('POST', uri);
  request.files.add(await http.MultipartFile.fromPath('file', audioPath));
  
  final response = await request.send();
  final body = await response.stream.bytesToString();
  return jsonDecode(body);
}
```

## 📝 Notes

- **Premier démarrage** : Le modèle Whisper sera téléchargé (peut prendre quelques minutes)
- **Mémoire** : Assurez-vous d'avoir assez de RAM pour le modèle choisi
- **Production** : Utilisez `gunicorn -w 4 -b 0.0.0.0:5000 app:app` pour la production

## 📚 Documentation Complète

Voir `STT_API_DOCUMENTATION.md` pour la documentation détaillée.

