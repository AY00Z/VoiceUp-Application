# Spécification des Endpoints API - Frontend ↔ Backend

Ce document détaille la correspondance exacte entre les endpoints du frontend et du backend.

## Authentification

**Headers attendus par le backend :**
- `Authorization: Bearer <token>` (optionnel pour prototype)
- `X-User-Id: <userId>` (pour prototype, simuler l'utilisateur local)
- `Content-Type: application/json` (pour les requêtes JSON)

**Implémentation frontend :** ✅ `lib/services/api_client.dart` ligne 17-30

---

## A. Contacts / Mock friends

### GET /api/contacts

**Backend attend :**
- Méthode: GET
- Headers: Authorization (optionnel), X-User-Id (optionnel)
- Réponse 200: Array de contacts
  ```json
  [
    { "id":"user-1", "name":"Amina", "avatarUrl":"..." },
    ...
  ]
  ```

**Frontend envoie :** ✅ `lib/services/contacts_service.dart` ligne 13-18
- GET `/api/contacts`
- Parse la réponse en `List<User>`

**Correspondance :** ✅ **MATCH**

---

## B. Conversations

### GET /api/conversations

**Backend attend :**
- Méthode: GET
- Réponse 200: Array de conversations
  ```json
  [
    {
      "id":"conv-1",
      "title":"Amina",
      "participantIds":["me","user-1"],
      "createdAt":"..."
    }
  ]
  ```

**Frontend envoie :** ✅ `lib/services/conversations_service.dart` ligne 13-18
- GET `/api/conversations`
- Parse en `List<Conversation>`

**Correspondance :** ✅ **MATCH**

### POST /api/conversations

**Backend attend :**
- Méthode: POST
- Body:
  ```json
  {
    "participantIds": ["me","user-2"],
    "title":"Nom"
  }
  ```
- Réponse 201: Conversation créée

**Frontend envoie :** ✅ `lib/services/conversations_service.dart` ligne 22-35
- POST `/api/conversations`
- Body: `{ "participantIds": [...], "title": "..." }`

**Correspondance :** ✅ **MATCH**

---

## C. Messages

### GET /api/conversations/:id/messages?limit=50&offset=0

**Backend attend :**
- Méthode: GET
- Query params: `limit` (int), `offset` (int)
- Réponse 200: Array de messages
  ```json
  [
    {
      "id":"msg-1",
      "conversationId":"conv-1",
      "senderId":"user-1",
      "type":"TEXT",
      "isEncrypted": true,
      "encryptedBlobUrl": null,
      "contentPreview": "Salut !",
      "transcriptionId": null,
      "createdAt":"..."
    },
    {
      "id":"msg-2",
      "conversationId":"conv-1",
      "senderId":"me",
      "type":"AUDIO",
      "isEncrypted": true,
      "encryptedBlobUrl":"https://.../blobs/msg-2.enc",
      "iv":"base64-iv",
      "transcriptionId":"trans-2",
      "createdAt":"..."
    }
  ]
  ```

**Frontend envoie :** ✅ `lib/services/messages_service.dart` ligne 14-31
- GET `/api/conversations/{conversationId}/messages?limit=50&offset=0`
- Parse en `List<Message>`

**Correspondance :** ✅ **MATCH**

### POST /api/conversations/:id/messages (Option 1 - Client-side encryption)

**Backend attend (message texte) :**
- Méthode: POST
- Headers: `Content-Type: application/json`
- Body:
  ```json
  {
    "type":"TEXT",
    "encryptedPayload": "base64-chiffre",
    "iv":"base64-iv",
    "plaintextPreview": "Bonjour",
    "meta": { "length": 12 }
  }
  ```
- Réponse 201: Message créé

**Frontend envoie :** ✅ `lib/services/messages_service.dart` ligne 35-57
- POST `/api/conversations/{conversationId}/messages`
- Body: `{ "type": "TEXT", "encryptedPayload": "...", "iv": "...", "plaintextPreview": "...", "meta": {...} }`

**Correspondance :** ✅ **MATCH**

**Backend attend (message audio, client-side) :**
- Méthode: POST
- Headers: `Content-Type: application/json`
- Body:
  ```json
  {
    "type":"AUDIO",
    "encryptedPayloadUrl":"https://upload-server/.../msg-2.enc",
    "iv":"base64-iv",
    "transcription": {
      "text":"Rendez-vous demain à 10h",
      "confidence": 0.94
    }
  }
  ```
- Réponse 201: Message créé (avec transcriptionId lié si fournie)

**Frontend envoie :** ✅ `lib/services/messages_service.dart` ligne 61-87
- POST `/api/conversations/{conversationId}/messages`
- Body: `{ "type": "AUDIO", "encryptedPayloadUrl": "...", "iv": "...", "transcription": {...} }`

**Correspondance :** ✅ **MATCH**

### POST /api/conversations/:id/messages?serverTranscribe=true (Option 2 - Server-side transcription)

**Backend attend :**
- Méthode: POST
- Query param: `serverTranscribe=true`
- Headers: `Content-Type: multipart/form-data`
- Body: `multipart/form-data` avec `file=audio` (en clair)
- Le serveur appelle STT, puis chiffre le blob pour stockage
- Réponse 201: Message créé (serveur fournit transcription)

**Frontend envoie :** ✅ `lib/services/messages_service.dart` ligne 91-107
- POST `/api/conversations/{conversationId}/messages?serverTranscribe=true`
- Multipart avec `file` field contenant l'audio en clair

**Correspondance :** ✅ **MATCH**

### GET /api/messages/:messageId

**Backend attend :**
- Méthode: GET
- Réponse 200: Métadonnées du message (sans blob)
  ```json
  {
    "id":"msg-2",
    "conversationId":"conv-1",
    "senderId":"me",
    "type":"AUDIO",
    "isEncrypted":true,
    "encryptedBlobUrl":"https://.../msg-2.enc",
    "iv":"base64-iv",
    "transcriptionId":"trans-2",
    "createdAt":"..."
  }
  ```

**Frontend envoie :** ✅ `lib/services/messages_service.dart` ligne 111-115
- GET `/api/messages/{messageId}`

**Correspondance :** ✅ **MATCH**

### GET /api/messages/:messageId/blob

**Backend attend :**
- Méthode: GET
- Vérifie que le demandeur fait partie de la conversation
- Réponse: 302 redirect vers CDN ou 200 binary (`application/octet-stream`)

**Frontend envoie :** ✅ `lib/services/messages_service.dart` ligne 119-122
- GET `/api/messages/{messageId}/blob`
- Retourne `Uint8List` (bytes)

**Correspondance :** ✅ **MATCH**

---

## D. Transcription

### GET /api/messages/:messageId/transcription

**Backend attend :**
- Méthode: GET
- Réponse 200:
  ```json
  {
    "id":"trans-2",
    "messageId":"msg-2",
    "text":"Rendez-vous demain à 10h",
    "confidence":0.94,
    "createdAt":"..."
  }
  ```

**Frontend envoie :** ✅ `lib/services/transcription_service.dart` ligne 14-18
- GET `/api/messages/{messageId}/transcription`

**Correspondance :** ✅ **MATCH**

### POST /api/transcribe (optionnel)

**Backend attend :**
- Méthode: POST
- Headers: `Content-Type: multipart/form-data`
- Body: `multipart/form-data` avec `file=audio`
- Réponse 200:
  ```json
  {
    "text":"Bonjour",
    "confidence":0.92
  }
  ```

**Frontend envoie :** ✅ `lib/services/transcription_service.dart` ligne 22-40
- POST `/api/transcribe`
- Multipart avec `file` field

**Correspondance :** ✅ **MATCH**

---

## E. Recherche

### GET /api/search?conversationId=:id&q=mot

**Backend attend :**
- Méthode: GET
- Query params: `conversationId` (UUID), `q` (string)
- Recherche dans messages texte (déchiffrés côté client) et transcriptions
- Réponse 200: Liste d'occurrences
  ```json
  [
    {
      "messageId":"msg-2",
      "excerpt":"...rendez-vous demain à 10h...",
      "type":"AUDIO",
      "createdAt":"..."
    }
  ]
  ```

**Frontend envoie :** ✅ `lib/services/search_service.dart` ligne 38-56
- GET `/api/search?conversationId={id}&q={query}`

**Correspondance :** ✅ **MATCH**

---

## F. Upload media

### POST /api/uploads

**Backend attend :**
- Méthode: POST
- Headers: `Content-Type: multipart/form-data`
- Body: `multipart/form-data` avec `file=...`
- Retourne URL (stockage CDN/S3)
- Réponse 200:
  ```json
  {
    "url": "https://cdn.../file.enc"
  }
  ```

**Frontend envoie :** ✅ `lib/services/upload_service.dart` ligne 13-29
- POST `/api/uploads`
- Multipart avec `file` field
- Parse `{ "url": "..." }`

**Correspondance :** ✅ **MATCH**

---

## G. Utilitaires

### GET /api/health

**Backend attend :**
- Méthode: GET
- Réponse 200: Vérifie que l'API fonctionne

**Frontend envoie :** ✅ `lib/services/api_service.dart` ligne 41-48
- GET `/api/health`

**Correspondance :** ✅ **MATCH**

### GET /api/version

**Backend attend :**
- Méthode: GET
- Réponse 200: Version du backend (texte ou JSON)

**Frontend envoie :** ✅ `lib/services/api_service.dart` ligne 52-65
- GET `/api/version`

**Correspondance :** ✅ **MATCH**

---

## Résumé

✅ **Tous les endpoints correspondent parfaitement !**

- ✅ Headers d'authentification corrects
- ✅ Méthodes HTTP correctes
- ✅ Formats de body corrects (JSON et multipart)
- ✅ Query parameters corrects
- ✅ Formats de réponse parsés correctement
- ✅ Gestion des erreurs implémentée

**Le frontend est prêt à communiquer avec le backend selon la spécification API fournie.**

