# Architecture et Flux de Données - VoiceUP Platform

## Vue d'Ensemble

```
┌─────────────────────────────────────────────────────────────────┐
│                        FRONTEND (Flutter)                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ ChatPage     │  │FriendsList   │  │ Encryption   │          │
│  │              │  │Page          │  │ Service      │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                  │                  │
│         └─────────────────┼──────────────────┘                  │
│                           │                                     │
│                  ┌────────▼────────┐                           │
│                  │   API Service   │                           │
│                  │   (HTTP Client)  │                           │
│                  └────────┬─────────┘                           │
└───────────────────────────┼─────────────────────────────────────┘
                            │ HTTP/REST
                            │
┌───────────────────────────▼─────────────────────────────────────┐
│                    BACKEND (Flask/Python)                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Routes     │  │   Models     │  │   Database   │          │
│  │   (app.py)   │  │  (SQLAlchemy)│  │  (SQLite/    │          │
│  │              │  │              │  │   PostgreSQL)│          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                  │                  │
│         └─────────────────┼──────────────────┘                  │
│                           │                                     │
│                  ┌────────▼────────┐                           │
│                  │  File Storage    │                           │
│                  │  (/uploads/)     │                           │
│                  └──────────────────┘                           │
└─────────────────────────────────────────────────────────────────┘
```

## Composants Principaux

### **Frontend (Flutter)**

1. **ChatPage** (`chat_page.dart`)
   - Interface de chat
   - Envoi de messages texte et audio
   - Lecture des messages vocaux
   - Gestion de l'état de lecture

2. **FriendsListPage** (`friends_list_page.dart`)
   - Liste des conversations
   - Affichage du dernier message
   - Date et heure du dernier message

3. **EncryptionService** (`encryption_service.dart`)
   - Chiffrement AES-256-CBC
   - Chiffrement de texte et binaires
   - Génération d'IV (Initialization Vector)

4. **API Services**
   - `ApiService`: Service principal
   - `MessagesService`: Gestion des messages
   - `ConversationsService`: Gestion des conversations
   - `ContactsService`: Gestion des contacts
   - `UploadService`: Upload de fichiers

### **Backend (Flask)**

1. **Routes** (`app.py`)
   - `GET /api/contacts` - Liste des utilisateurs
   - `GET /api/conversations` - Liste des conversations
   - `POST /api/conversations` - Créer une conversation
   - `GET /api/conversations/<id>/messages` - Messages d'une conversation
   - `POST /api/conversations/<id>/messages` - Envoyer un message
   - `POST /api/uploads` - Upload de fichier
   - `GET /api/uploads/<filename>` - Télécharger un fichier

2. **Models** (`models.py`)
   - `User`: Utilisateurs
   - `Conversation`: Conversations
   - `Message`: Messages
   - `Transcription`: Transcriptions audio

3. **Database**
   - SQLAlchemy ORM
   - Relations Many-to-Many (Users ↔ Conversations)
   - Stockage des messages chiffrés

## Flux de Données Détaillé

### **1. Envoi Message Texte**

```
User Input → ChatPage → EncryptionService → API Service → Backend → Database
   (text)     (UI)        (encrypt)         (HTTP POST)   (save)    (store)
```

**Étapes:**
1. Utilisateur tape un message
2. ChatPage appelle `EncryptionService.encryptText()`
3. Retour: `encryptedPayload` (base64) + `IV` (base64)
4. API Service envoie POST avec payload chiffré
5. Backend sauvegarde en DB (chiffré)
6. Retour du message créé avec ID

### **2. Envoi Message Audio**

```
Record → Read File → Encrypt → Upload → Save URL → Create Message
  (audio)  (bytes)   (binary)  (POST)    (DB)      (POST)
```

**Étapes:**
1. Enregistrement audio (WAV sur web)
2. Lecture du fichier en bytes
3. Chiffrement avec `encryptBinary()`
4. Upload du fichier chiffré → `/api/uploads`
5. Retour de l'URL du fichier
6. Création du message avec l'URL chiffrée

### **3. Affichage Messages**

```
Load Page → Get Messages → Decrypt → Display
  (init)      (GET)         (client)  (UI)
```

**Étapes:**
1. Chargement de la page
2. GET `/api/conversations/<id>/messages`
3. Backend retourne messages chiffrés
4. Frontend déchiffre chaque message
5. Affichage dans l'UI

### **4. Lecture Audio**

```
Click Play → Fetch File → Decrypt → Create Blob → Play
  (user)     (GET)        (binary)   (web)        (player)
```

**Étapes:**
1. Clic sur play
2. GET `/api/uploads/<filename>` (fichier chiffré)
3. Déchiffrement avec IV du message
4. Création blob URL (web) ou fichier temp (mobile)
5. Lecture avec AudioPlayer

## Sécurité

### **Chiffrement**
- **Algorithme**: AES-256-CBC
- **Clé**: 32 bytes (partagée pour prototype)
- **IV**: 16 bytes, unique par message
- **Format**: Base64 pour texte, bytes pour audio

### **Stockage**
- Messages texte: Payload chiffré en DB
- Messages audio: Fichiers chiffrés dans `/uploads/`
- IV stocké avec chaque message
- Pas de données en clair en DB

### **Transport**
- HTTPS recommandé (non implémenté en dev)
- CORS activé pour le développement
- Headers: `X-User-Id` pour identification (prototype)

## Points d'Attention

1. **Clé de chiffrement**: Actuellement hardcodée (prototype)
   - Production: Key exchange ou dérivation depuis mot de passe

2. **Gestion des erreurs**: 
   - Réessai automatique
   - Messages d'erreur utilisateur

3. **Performance**:
   - Messages chargés par batch (limit/offset)
   - Derniers messages chargés en arrière-plan

4. **Web vs Mobile**:
   - Web: Blob URLs pour audio
   - Mobile: Fichiers temporaires


