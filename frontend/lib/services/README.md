# Services API

Cette structure de services permet de connecter le frontend Flutter au backend.

## Structure

- **api_client.dart** : Client HTTP de base avec gestion des erreurs
- **api_service.dart** : Service principal qui agrège tous les autres services
- **contacts_service.dart** : Gestion des contacts/amis
- **conversations_service.dart** : Gestion des conversations
- **messages_service.dart** : Gestion des messages (texte et audio)
- **transcription_service.dart** : Gestion des transcriptions
- **search_service.dart** : Recherche dans les messages
- **upload_service.dart** : Upload de fichiers (blobs chiffrés)

## Configuration

Modifiez `lib/config/api_config.dart` pour configurer l'URL du backend :

```dart
static const String baseUrl = 'http://localhost:3000';
```

## Utilisation

```dart
import 'package:frontend/config/api_config.dart';
import 'package:frontend/services/api_service.dart';

// Créer une instance du service API
final apiService = ApiConfig.createApiService();

// Utiliser les services
final contacts = await apiService.contacts.getContacts();
final conversations = await apiService.conversations.getConversations();
final messages = await apiService.messages.getMessages(conversationId);
```

## Endpoints implémentés

### Contacts
- ✅ GET /api/contacts

### Conversations
- ✅ GET /api/conversations
- ✅ POST /api/conversations

### Messages
- ✅ GET /api/conversations/:id/messages
- ✅ POST /api/conversations/:id/messages (texte)
- ✅ POST /api/conversations/:id/messages (audio)
- ✅ POST /api/conversations/:id/messages?serverTranscribe=true
- ✅ GET /api/messages/:messageId
- ✅ GET /api/messages/:messageId/blob

### Transcriptions
- ✅ GET /api/messages/:messageId/transcription
- ✅ POST /api/transcribe

### Recherche
- ✅ GET /api/search

### Upload
- ✅ POST /api/uploads

### Utilitaires
- ✅ GET /api/health
- ✅ GET /api/version

## Authentification

Pour le prototype, utilisez l'en-tête `X-User-Id`. Pour la production, utilisez `Authorization: Bearer <token>`.

```dart
ApiConfig.userId = 'user-123';
ApiConfig.authToken = 'your-token'; // Optionnel pour prototype
```

