# STT_API - Speech-to-Text Transcription Service

## 📋 Qu'est-ce que cette API ?

**STT_API** est un service de transcription vocale (Speech-to-Text) basé sur **Whisper** (modèle d'OpenAI). Il convertit des fichiers audio en texte.

### Fonctionnalités principales :

1. **Transcription audio** : Convertit n'importe quel fichier audio (WAV, MP3, M4A, FLAC, OGG, WebM) en texte
2. **Pré-traitement automatique** : Convertit automatiquement l'audio en format 16kHz mono WAV (optimal pour Whisper)
3. **Confidence score** : Retourne un score de confiance pour la transcription
4. **Segments détaillés** : Retourne la transcription avec timestamps (début/fin de chaque segment)

## 🏗️ Architecture

```
STT_API/
└── VoiceUP/
    └── api/
        └── VoiceUP/
            └── STT_API/
                ├── app.py              # API Flask principale
                ├── client_post.py      # Script de test (optionnel)
                ├── export_to_onnx.py   # Export du modèle (optionnel)
                ├── requirements.txt    # Dépendances Python
                ├── README.md           # Documentation originale
                └── utils/
                    └── audio.py        # Utilitaires de traitement audio
```

## 🔧 Comment ça fonctionne ?

### Flux de traitement :

```
1. Client envoie fichier audio
   ↓
2. API reçoit le fichier (multipart/form-data)
   ↓
3. Pré-traitement : Conversion en 16kHz mono WAV
   ↓
4. Whisper Model : Transcription de l'audio
   ↓
5. Post-traitement : Calcul de la confiance
   ↓
6. Retour JSON : {transcription, confidence, segments, info}
```

### Modèle Whisper :

- **Modèles disponibles** : `tiny`, `small`, `medium`, `large-v3`
- **Device** : CPU ou CUDA (GPU)
- **Par défaut** : `tiny` sur `cpu` (rapide mais moins précis)
- **Recommandé pour production** : `small` ou `medium` (meilleure précision)

## 🚀 Installation et Démarrage

### Prérequis :

```bash
# Python 3.8+
# pip install -r requirements.txt
```

### 1. Installer les dépendances

```bash
cd STT_API/VoiceUP/api/VoiceUP/STT_API
pip install -r requirements.txt
```

**Dépendances principales :**
- `Flask` - Framework web
- `faster-whisper` - Implémentation optimisée de Whisper
- `torch` / `torchaudio` - Backend pour Whisper
- `librosa` - Traitement audio
- `soundfile` - Lecture/écriture fichiers audio

### 2. Configuration (Optionnel)

Variables d'environnement :

```bash
# Modèle Whisper (tiny, small, medium, large-v3)
export WHISPER_MODEL=tiny

# Device (cpu ou cuda pour GPU)
export WHISPER_DEVICE=cpu

# Type de calcul (float16 pour GPU, None pour CPU)
export WHISPER_COMPUTE=float16  # Seulement si cuda
```

### 3. Lancer l'API

**Mode développement :**
```bash
cd STT_API/VoiceUP/api/VoiceUP/STT_API
python app.py
```

L'API démarre sur : `http://0.0.0.0:5000`

**Mode production (recommandé) :**
```bash
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

## 📡 Endpoints API

### 1. **GET /health**

Vérifier que l'API fonctionne.

**Réponse :**
```json
{
  "status": "ok",
  "model": "tiny",
  "device": "cpu"
}
```

### 2. **POST /transcribe**

Transcrire un fichier audio.

**Request :**
- Method: `POST`
- Content-Type: `multipart/form-data`
- Field: `file` (fichier audio)
- Formats supportés: `.wav`, `.mp3`, `.m4a`, `.flac`, `.ogg`, `.webm`
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

**Champs de la réponse :**
- `transcription` : Texte complet transcrit
- `confidence` : Score de confiance (0.0 à 1.0, ou null)
- `segments` : Liste des segments avec timestamps
- `info` : Informations supplémentaires (langue détectée, etc.)

## 🔌 Intégration avec votre Application Flutter

### Utilisation depuis votre frontend Flutter :

```dart
import 'package:http/http.dart' as http;
import 'dart:io';

Future<Map<String, dynamic>> transcribeAudio(String audioFilePath) async {
  final uri = Uri.parse('http://127.0.0.1:5000/transcribe');
  final request = http.MultipartRequest('POST', uri);
  
  // Ajouter le fichier audio
  final file = await http.MultipartFile.fromPath('file', audioFilePath);
  request.files.add(file);
  
  // Envoyer la requête
  final response = await request.send();
  final responseBody = await response.stream.bytesToString();
  
  // Parser la réponse JSON
  return jsonDecode(responseBody);
}
```

### Exemple d'utilisation dans votre chat :

```dart
// Après avoir enregistré un message vocal
Future<void> _sendVoiceMessage() async {
  // ... (votre code existant pour enregistrer et chiffrer)
  
  // Optionnel : Transcrire l'audio avant d'envoyer
  try {
    final transcription = await transcribeAudio(recordingPath);
    final text = transcription['transcription'] as String;
    final confidence = transcription['confidence'] as double?;
    
    // Envoyer le message avec la transcription
    final message = await _apiService.messages.sendAudioMessage(
      conversationId: widget.conversation.id,
      encryptedPayloadUrl: blobUrl,
      iv: iv,
      transcriptionText: text,  // Transcription incluse
      transcriptionConfidence: confidence,
    );
  } catch (e) {
    // Si la transcription échoue, envoyer quand même le message audio
    print('Transcription failed: $e');
  }
}
```

## 🧪 Tester l'API

### Test avec curl :

```bash
# Tester le health endpoint
curl http://127.0.0.1:5000/health

# Transcrire un fichier audio
curl -X POST http://127.0.0.1:5000/transcribe \
  -F "file=@/path/to/your/audio.wav"
```

### Test avec le script Python :

```bash
cd STT_API/VoiceUP/api/VoiceUP/STT_API
python client_post.py /path/to/audio.wav
```

## ⚙️ Configuration Avancée

### Modèles Whisper disponibles :

| Modèle | Taille | Vitesse | Précision | RAM requise |
|--------|--------|---------|-----------|-------------|
| `tiny` | 39 MB | ⚡⚡⚡ Très rapide | ⭐⭐ Basique | ~1 GB |
| `small` | 244 MB | ⚡⚡ Rapide | ⭐⭐⭐ Bonne | ~2 GB |
| `medium` | 769 MB | ⚡ Modéré | ⭐⭐⭐⭐ Très bonne | ~5 GB |
| `large-v3` | 1550 MB | 🐌 Lent | ⭐⭐⭐⭐⭐ Excellente | ~10 GB |

**Recommandation :**
- **Développement** : `tiny` (rapide)
- **Production** : `small` ou `medium` (bon compromis)

### Utilisation GPU (CUDA) :

Si vous avez un GPU NVIDIA :

```bash
export WHISPER_MODEL=small
export WHISPER_DEVICE=cuda
export WHISPER_COMPUTE=float16
python app.py
```

## 🔒 Sécurité et Performance

### Limitations :
- Taille max fichier : 50 MB
- Formats supportés : WAV, MP3, M4A, FLAC, OGG, WebM
- Pas d'authentification (à ajouter en production)

### Performance :
- **Tiny model** : ~1-2 secondes pour 10 secondes d'audio
- **Small model** : ~3-5 secondes pour 10 secondes d'audio
- **Medium model** : ~10-15 secondes pour 10 secondes d'audio

### Optimisations :
- Le modèle est chargé une seule fois au démarrage
- Les fichiers temporaires sont nettoyés automatiquement
- Support du threading pour gérer plusieurs requêtes

## 📝 Notes Importantes

1. **Premier démarrage** : Le modèle Whisper sera téléchargé automatiquement (peut prendre quelques minutes)

2. **Mémoire** : Assurez-vous d'avoir assez de RAM pour le modèle choisi

3. **Réseau** : Le premier téléchargement du modèle nécessite une connexion internet

4. **Production** : Utilisez `gunicorn` avec plusieurs workers pour gérer la charge

5. **Intégration** : Cette API peut être utilisée comme fallback si la transcription locale (ONNX) échoue dans votre app Flutter

## 🔗 Intégration avec VoiceUP Backend

Vous pouvez intégrer cette API dans votre backend principal (`backend/VoiceUP/VoiceUP_Backend/app.py`) pour :

1. **Transcription côté serveur** : Transcrire les messages audio automatiquement
2. **Fallback** : Si la transcription client échoue
3. **Amélioration** : Utiliser un modèle plus puissant que celui côté client

**Exemple d'intégration :**
```python
# Dans app.py
import requests

def transcribe_audio_server_side(audio_file_path):
    """Appelle l'API STT pour transcrire un fichier audio"""
    url = "http://127.0.0.1:5000/transcribe"  # STT_API
    with open(audio_file_path, 'rb') as f:
        files = {'file': f}
        response = requests.post(url, files=files)
        return response.json()
```

