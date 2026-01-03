# Intégration STT_API dans le Flux des Messages

## 📋 Vue d'ensemble

L'API STT (Speech-to-Text) a été intégrée dans le flux des messages vocaux selon le diagramme de séquence fourni. Le processus suit maintenant ces étapes :

1. **Enregistrement** : L'utilisateur enregistre un message vocal
2. **Transcription** : L'audio est transcrit via STT_API (avant chiffrement)
3. **Chiffrement** : L'audio est chiffré avec AES-256
4. **Upload** : Le blob chiffré est uploadé
5. **Envoi** : Le message est envoyé avec la transcription

## 🔄 Flux Complet

### Phase 1: Client-Side Processing

```
User (Mobile) → STT Module → Encryption (AES-256)
```

1. **Enregistrement** : `.wav` file créé
2. **Transcription** : Audio envoyé à STT_API (`http://127.0.0.1:5001/transcribe`)
   - Retourne : `{ text, confidence, segments, info }`
3. **Chiffrement** : Audio + User Key → Blob chiffré (`.enc`) + IV

### Phase 2: Data Transmission

```
User (Mobile) → Flask Backend
```

**POST** `/api/conversations/:id/messages` (JSON)
- Body inclut :
  - `encryptedPayloadUrl` : URL du blob chiffré
  - `iv` : Initialization Vector
  - `senderId` : ID de l'expéditeur
  - `transcription` : `{ text, confidence }`

### Phase 3: Backend Persistence

```
Flask Backend → File System + PostgreSQL
```

1. **Sauvegarde fichier** : `.enc` file sauvegardé dans `/uploads`
2. **INSERT message** : Métadonnées dans table `message`
3. **INSERT transcription** : Texte + confidence dans table `transcription`

### Phase 4: Search & Retrieval

```
User (Mobile) → Flask Backend → PostgreSQL
```

**GET** `/api/search?conversationId=<id>&q=<keyword>`
- Recherche dans les transcriptions et les aperçus de messages texte
- Retourne : Liste de résultats avec excerpts

## 📁 Fichiers Modifiés/Créés

### Frontend (Flutter)

1. **`lib/services/stt_service.dart`** (NOUVEAU)
   - Service pour appeler STT_API
   - Méthodes :
     - `transcribeAudio()` : Transcrit un fichier audio
     - `checkHealth()` : Vérifie que STT_API est disponible

2. **`lib/services/api_service.dart`** (MODIFIÉ)
   - Ajout de `SttService stt` dans `ApiService`

3. **`lib/screens/chat_page.dart`** (MODIFIÉ)
   - `_sendVoiceMessage()` mis à jour pour :
     1. Lire l'audio
     2. **Appeler STT_API** (nouveau)
     3. Chiffrer l'audio
     4. Uploader le blob
     5. Envoyer avec transcription

### Backend (Flask)

1. **`app.py`** (MODIFIÉ)
   - Ajout de l'endpoint `/api/search` :
     - Recherche dans les transcriptions
     - Recherche dans les aperçus de messages texte
     - Retourne des excerpts avec contexte

## 🚀 Comment Utiliser

### 1. Démarrer STT_API

```bash
cd STT_API/VoiceUP/api/VoiceUP/STT_API
pip install -r requirements.txt
python app.py
```

STT_API démarre sur **http://127.0.0.1:5001**

### 2. Démarrer le Backend Principal

```bash
cd backend/VoiceUP/VoiceUP_Backend
python app.py
```

Backend démarre sur **http://127.0.0.1:5000**

### 3. Lancer l'Application Flutter

```bash
cd frontend
flutter run
```

### 4. Tester le Flux

1. Ouvrir une conversation
2. Enregistrer un message vocal
3. Le message est automatiquement transcrit via STT_API
4. L'aperçu du message affiche la transcription
5. La transcription est sauvegardée dans la base de données

### 5. Tester la Recherche

```bash
curl "http://127.0.0.1:5000/api/search?conversationId=<conv_id>&q=keyword"
```

## 🔍 Détails Techniques

### STT Service

```dart
// Exemple d'utilisation
final sttResult = await _apiService.stt.transcribeAudio(
  audioBytes: audioBytes,
  fileName: 'voice.wav',
);

String? text = sttResult['text'];
double? confidence = sttResult['confidence'];
```

### Envoi de Message avec Transcription

```dart
final message = await _apiService.messages.sendAudioMessage(
  conversationId: conversationId,
  encryptedPayloadUrl: blobUrl,
  iv: iv,
  transcriptionText: transcriptionText,
  transcriptionConfidence: transcriptionConfidence,
);
```

### Recherche

```dart
final results = await _apiService.search.search(
  conversationId: conversationId,
  query: 'keyword',
);
```

## ⚠️ Notes Importantes

1. **STT_API doit être démarré** : Si STT_API n'est pas disponible, l'envoi continue sans transcription (avec un warning dans les logs)

2. **Ports** :
   - Backend principal : `5000`
   - STT_API : `5001`

3. **Transcription avant chiffrement** : La transcription se fait sur l'audio en clair (avant chiffrement), ce qui est nécessaire pour que STT_API puisse traiter l'audio

4. **Gestion d'erreurs** : Si STT_API échoue, le message vocal est quand même envoyé (sans transcription)

## 📊 Structure de la Base de Données

### Table `transcription`

```sql
- id (UUID)
- messageId (UUID, FK → message.id)
- text (TEXT) - Le texte transcrit
- confidence (FLOAT) - Score de confiance (0.0 à 1.0)
- createdAt (DATETIME)
```

## ✅ Checklist d'Intégration

- [x] Service STT créé
- [x] STT intégré dans le flux d'envoi
- [x] Transcription envoyée au backend
- [x] Backend sauvegarde la transcription
- [x] Endpoint de recherche implémenté
- [x] Recherche dans transcriptions fonctionnelle
- [x] Gestion d'erreurs STT_API

## 🎯 Prochaines Étapes (Optionnel)

1. **Cache de transcription** : Éviter de re-transcrire le même audio
2. **Transcription asynchrone** : Transmettre l'audio, transcrire en arrière-plan
3. **Indicateur de transcription** : Afficher un loader pendant la transcription
4. **Langue détectée** : Utiliser la langue détectée par STT_API

