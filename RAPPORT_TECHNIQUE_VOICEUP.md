# 📋 Rapport Technique - VoiceUP

**Application de Messagerie Vocale Sécurisée avec Transcription Automatique**

---

## 📑 Table des Matières

1. [Introduction](#introduction)
2. [Besoins Fonctionnels](#besoins-fonctionnels)
3. [Besoins Non Fonctionnels](#besoins-non-fonctionnels)
4. [Architecture Logicielle](#architecture-logicielle)
5. [Architecture Physique](#architecture-physique)
6. [Technologies Utilisées](#technologies-utilisées)
7. [Sécurité](#sécurité)
8. [Conclusion](#conclusion)

---

## 1. Introduction

**VoiceUP** est une application de messagerie instantanée sécurisée permettant l'envoi de messages texte et vocaux avec chiffrement end-to-end (E2EE). L'application intègre un système de transcription automatique des messages vocaux utilisant l'intelligence artificielle (Whisper), permettant la recherche dans le contenu des messages audio.

### Objectifs du Projet

- Fournir une communication sécurisée avec chiffrement AES-256
- Permettre l'envoi et la réception de messages texte et vocaux
- Transcrire automatiquement les messages vocaux pour faciliter la recherche
- Offrir une interface utilisateur moderne et intuitive
- Assurer la compatibilité multi-plateforme (Web, Android, iOS)

---

## 2. Besoins Fonctionnels

### 2.1 Gestion des Utilisateurs

| ID | Besoin Fonctionnel | Description | Priorité |
|----|-------------------|-------------|----------|
| BF-01 | Authentification | Système de connexion avec email et mot de passe | Haute |
| BF-02 | Gestion du profil | Affichage du profil utilisateur (nom, avatar) | Moyenne |
| BF-03 | Liste des contacts | Affichage de la liste des utilisateurs disponibles | Haute |

### 2.2 Gestion des Conversations

| ID | Besoin Fonctionnel | Description | Priorité |
|----|-------------------|-------------|----------|
| BF-04 | Création de conversation | Créer une nouvelle conversation avec un ou plusieurs contacts | Haute |
| BF-05 | Liste des conversations | Afficher toutes les conversations de l'utilisateur | Haute |
| BF-06 | Affichage du dernier message | Afficher le dernier message de chaque conversation avec date/heure | Haute |
| BF-07 | Titre dynamique | Générer automatiquement le titre de la conversation | Moyenne |

### 2.3 Gestion des Messages

| ID | Besoin Fonctionnel | Description | Priorité |
|----|-------------------|-------------|----------|
| BF-08 | Envoi de message texte | Envoyer un message texte chiffré | Haute |
| BF-09 | Envoi de message vocal | Enregistrer, chiffrer et envoyer un message vocal | Haute |
| BF-10 | Réception de messages | Recevoir et afficher les messages (texte et audio) | Haute |
| BF-11 | Lecture de messages vocaux | Jouer les messages vocaux reçus | Haute |
| BF-12 | Affichage des messages | Afficher l'historique des messages d'une conversation | Haute |
| BF-13 | Indicateur de lecture | Afficher si un message a été lu | Moyenne |
| BF-14 | Horodatage | Afficher la date et l'heure d'envoi de chaque message | Haute |

### 2.4 Transcription et Recherche

| ID | Besoin Fonctionnel | Description | Priorité |
|----|-------------------|-------------|----------|
| BF-15 | Transcription automatique | Transcrire automatiquement les messages vocaux | Haute |
| BF-16 | Recherche dans les messages | Rechercher un mot-clé dans les messages texte et transcriptions | Haute |
| BF-17 | Affichage de la transcription | Afficher la transcription sous les messages vocaux | Moyenne |
| BF-18 | Score de confiance | Afficher le score de confiance de la transcription | Basse |

### 2.5 Chiffrement et Sécurité

| ID | Besoin Fonctionnel | Description | Priorité |
|----|-------------------|-------------|----------|
| BF-19 | Chiffrement des messages texte | Chiffrer les messages texte avec AES-256-CBC | Haute |
| BF-20 | Chiffrement des messages audio | Chiffrer les fichiers audio avec AES-256-CBC | Haute |
| BF-21 | Génération d'IV | Générer un IV unique pour chaque message | Haute |
| BF-22 | Déchiffrement côté client | Déchiffrer les messages uniquement côté client | Haute |

### 2.6 Interface Utilisateur

| ID | Besoin Fonctionnel | Description | Priorité |
|----|-------------------|-------------|----------|
| BF-23 | Interface responsive | Adapter l'interface aux dimensions mobiles | Haute |
| BF-24 | Navigation entre pages | Navigation fluide entre les différentes pages | Haute |
| BF-25 | Indicateurs visuels | Afficher les indicateurs de chargement, erreurs, etc. | Moyenne |
| BF-26 | Recherche dans conversation | Barre de recherche dans la page de chat | Haute |

---

## 3. Besoins Non Fonctionnels

### 3.1 Performance

| ID | Besoin Non Fonctionnel | Description | Critère |
|----|------------------------|-------------|---------|
| BNF-01 | Temps de réponse API | Les requêtes API doivent répondre en moins de 2 secondes | < 2s |
| BNF-02 | Temps de transcription | La transcription d'un message vocal doit se faire en moins de 10 secondes | < 10s |
| BNF-03 | Chargement des messages | L'affichage des messages doit être fluide (60 FPS) | 60 FPS |
| BNF-04 | Pagination | Charger les messages par batch pour éviter les surcharges | 50 messages/batch |

### 3.2 Sécurité

| ID | Besoin Non Fonctionnel | Description | Critère |
|----|------------------------|-------------|---------|
| BNF-05 | Chiffrement E2EE | Les messages doivent être chiffrés avant l'envoi | AES-256-CBC |
| BNF-06 | Stockage sécurisé | Aucune donnée sensible en clair dans la base de données | 100% chiffré |
| BNF-07 | Transport sécurisé | Utiliser HTTPS en production | TLS 1.3+ |
| BNF-08 | Gestion des clés | Clés de chiffrement gérées côté client uniquement | Client-side |

### 3.3 Disponibilité

| ID | Besoin Non Fonctionnel | Description | Critère |
|----|------------------------|-------------|---------|
| BNF-09 | Uptime | L'application doit être disponible 99% du temps | 99% |
| BNF-10 | Gestion des erreurs | Gestion gracieuse des erreurs réseau | Retry automatique |
| BNF-11 | Fallback | Continuer à fonctionner même si STT_API est indisponible | Dégradé gracieux |

### 3.4 Scalabilité

| ID | Besoin Non Fonctionnel | Description | Critère |
|----|------------------------|-------------|---------|
| BNF-12 | Support multi-utilisateurs | Support de plusieurs utilisateurs simultanés | 100+ utilisateurs |
| BNF-13 | Stockage | Support de grandes quantités de messages | Illimité (avec pagination) |
| BNF-14 | Fichiers audio | Support de fichiers audio jusqu'à 50 MB | 50 MB max |

### 3.5 Maintenabilité

| ID | Besoin Non Fonctionnel | Description | Critère |
|----|------------------------|-------------|---------|
| BNF-15 | Code modulaire | Architecture modulaire et réutilisable | Services séparés |
| BNF-16 | Documentation | Code documenté et commenté | 80%+ documenté |
| BNF-17 | Tests | Tests unitaires et d'intégration | 70%+ couverture |

### 3.6 Compatibilité

| ID | Besoin Non Fonctionnel | Description | Critère |
|----|------------------------|-------------|---------|
| BNF-18 | Multi-plateforme | Support Web, Android, iOS | 3 plateformes |
| BNF-19 | Navigateurs | Compatible avec Chrome, Edge, Firefox | 3+ navigateurs |
| BNF-20 | Versions OS | Support Android 8+, iOS 12+ | Versions récentes |

### 3.7 Utilisabilité

| ID | Besoin Non Fonctionnel | Description | Critère |
|----|------------------------|-------------|---------|
| BNF-21 | Interface intuitive | Interface facile à utiliser sans formation | UX intuitive |
| BNF-22 | Feedback utilisateur | Messages d'erreur clairs et informatifs | Messages explicites |
| BNF-23 | Accessibilité | Support des standards d'accessibilité | WCAG 2.1 AA |

---

## 4. Architecture Logicielle

### 4.1 Vue d'Ensemble

L'architecture de VoiceUP suit le modèle **Client-Serveur** avec une séparation claire entre :
- **Frontend** : Application Flutter (Web/Mobile)
- **Backend** : API REST Flask (Python)
- **STT_API** : Service de transcription indépendant (Python/Flask)

### 4.2 Architecture en Couches

```
┌─────────────────────────────────────────────────────────────┐
│                    COUCHE PRÉSENTATION                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  LoginPage   │  │FriendsListPage│  │  ChatPage    │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │                  │                  │
┌─────────▼──────────────────▼──────────────────▼─────────────┐
│                    COUCHE MÉTIER                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Encryption   │  │  STT Service │  │ API Services │     │
│  │   Service    │  │              │  │              │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │                  │                  │
┌─────────▼──────────────────▼──────────────────▼─────────────┐
│                    COUCHE ACCÈS DONNÉES                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  API Client  │  │  HTTP Client │  │ File Helper  │     │
│  │   (REST)     │  │              │  │              │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │                  │                  │
          └──────────────────┼──────────────────┘
                             │
          ┌──────────────────▼──────────────────┐
          │         BACKEND (Flask API)          │
          │  ┌──────────┐  ┌──────────┐         │
          │  │  Routes  │  │  Models  │         │
          │  └────┬─────┘  └────┬─────┘         │
          │       │             │                │
          │       └──────┬──────┘                │
          │              │                       │
          │       ┌──────▼──────┐                │
          │       │  Database   │                │
          │       │ (PostgreSQL)│                │
          │       └─────────────┘                │
          └──────────────────────────────────────┘
```

### 4.3 Modèle de Données

#### 4.3.1 Entités Principales

**User (Utilisateur)**
- `id` : UUID (clé primaire)
- `name` : String (nom de l'utilisateur)
- `avatarUrl` : String (URL de l'avatar)
- `createdAt` : DateTime

**Conversation (Conversation)**
- `id` : UUID (clé primaire)
- `title` : String (titre de la conversation)
- `createdAt` : DateTime
- `users` : Relation Many-to-Many avec User

**Message (Message)**
- `id` : UUID (clé primaire)
- `conversationId` : UUID (clé étrangère)
- `senderId` : UUID (clé étrangère)
- `type` : String ('TEXT' ou 'AUDIO')
- `isEncrypted` : Boolean
- `encryptedPayload` : Text (pour messages texte)
- `encryptedBlobUrl` : String (pour messages audio)
- `iv` : String (Initialization Vector)
- `contentPreview` : Text (aperçu non chiffré)
- `createdAt` : DateTime
- `isRead` : Boolean

**Transcription (Transcription)**
- `id` : UUID (clé primaire)
- `messageId` : UUID (clé étrangère, unique)
- `text` : Text (texte transcrit)
- `confidence` : Float (score de confiance 0.0-1.0)
- `createdAt` : DateTime

#### 4.3.2 Relations

```
User ──< Message (1-to-Many)
User ──< Conversation (Many-to-Many via participants)
Conversation ──< Message (1-to-Many)
Message ──< Transcription (1-to-1)
```

### 4.4 Flux de Données

#### 4.4.1 Envoi de Message Texte

```
1. User Input (texte)
   ↓
2. ChatPage → EncryptionService.encryptText()
   ↓
3. Génération IV + Chiffrement AES-256-CBC
   ↓
4. API Service → POST /api/conversations/:id/messages
   Body: { type: "TEXT", encryptedPayload: "...", iv: "..." }
   ↓
5. Backend → Validation + Insertion en DB
   ↓
6. Retour: Message créé avec ID
   ↓
7. Mise à jour UI
```

#### 4.4.2 Envoi de Message Vocal

```
1. Enregistrement Audio (.wav)
   ↓
2. Lecture fichier → audioBytes
   ↓
3. STT_API → POST /transcribe
   Retour: { text: "...", confidence: 0.95 }
   ↓
4. EncryptionService.encryptBinary(audioBytes)
   Retour: { encryptedData: Uint8List, iv: String }
   ↓
5. Upload → POST /api/uploads
   Retour: { url: "/api/uploads/file.enc" }
   ↓
6. POST /api/conversations/:id/messages
   Body: { type: "AUDIO", encryptedPayloadUrl: "...", iv: "...", transcription: {...} }
   ↓
7. Backend → Sauvegarde fichier + Insertion DB
   ↓
8. Retour: Message créé
```

#### 4.4.3 Lecture de Message Vocal

```
1. User Click Play
   ↓
2. GET /api/uploads/:filename (fichier chiffré)
   ↓
3. Récupération IV depuis message
   ↓
4. EncryptionService.decryptBinary(encryptedBytes, iv)
   ↓
5. Création Blob URL (web) ou fichier temp (mobile)
   ↓
6. AudioPlayer.play(blobUrl)
```

#### 4.4.4 Recherche dans les Messages

```
1. User Input (mot-clé)
   ↓
2. GET /api/search?conversationId=:id&q=keyword
   ↓
3. Backend → Requête SQL:
   SELECT * FROM message 
   JOIN transcription 
   WHERE text LIKE %keyword% OR contentPreview LIKE %keyword%
   ↓
4. Retour: Liste de résultats avec excerpts
   ↓
5. Affichage + Navigation entre résultats
```

### 4.5 Services et Modules

#### Frontend (Flutter)

**Services**
- `ApiService` : Service principal agrégateur
- `MessagesService` : Gestion des messages
- `ConversationsService` : Gestion des conversations
- `ContactsService` : Gestion des contacts
- `UploadService` : Upload de fichiers
- `SttService` : Appels à STT_API
- `SearchService` : Recherche dans les messages
- `TranscriptionService` : Gestion des transcriptions
- `EncryptionService` : Chiffrement/déchiffrement AES-256

**Screens**
- `LoginPage` : Page de connexion
- `FriendsListPage` : Liste des conversations
- `ChatPage` : Interface de chat

**Models**
- `User` : Modèle utilisateur
- `Conversation` : Modèle conversation
- `Message` : Modèle message
- `Transcription` : Modèle transcription

#### Backend (Flask)

**Routes** (`app.py`)
- `GET /api/contacts` : Liste des utilisateurs
- `GET /api/conversations` : Liste des conversations
- `POST /api/conversations` : Créer une conversation
- `GET /api/conversations/:id/messages` : Messages d'une conversation
- `POST /api/conversations/:id/messages` : Envoyer un message
- `POST /api/uploads` : Upload de fichier
- `GET /api/uploads/:filename` : Télécharger un fichier
- `GET /api/search` : Rechercher dans les messages
- `GET /api/messages/:id` : Détails d'un message
- `GET /api/messages/:id/transcription` : Transcription d'un message

**Models** (`models.py`)
- `User` : Modèle SQLAlchemy
- `Conversation` : Modèle SQLAlchemy
- `Message` : Modèle SQLAlchemy
- `Transcription` : Modèle SQLAlchemy

#### STT_API (Flask)

**Routes** (`app.py`)
- `GET /health` : Vérification de l'état
- `POST /transcribe` : Transcription d'un fichier audio

**Utils**
- `audio.py` : Pré-traitement audio (conversion en 16kHz mono WAV)

---

## 5. Architecture Physique

### 5.1 Déploiement

```
┌─────────────────────────────────────────────────────────────┐
│                      CLIENT DEVICES                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Web App    │  │ Android App  │  │   iOS App    │     │
│  │  (Chrome)    │  │              │  │              │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │                  │                  │
          │                  │                  │
          └──────────────────┼──────────────────┘
                             │
                    ┌────────▼────────┐
                    │   Load Balancer │
                    │   (Nginx/Apache)│
                    └────────┬────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
    ┌─────▼─────┐      ┌─────▼─────┐     ┌─────▼─────┐
    │  Backend  │      │  STT_API  │     │  Database  │
    │   Flask   │      │   Flask   │     │ PostgreSQL │
    │  :5000    │      │  :5001    │     │   :5432    │
    └─────┬─────┘      └───────────┘     └─────┬─────┘
          │                                     │
          └──────────────┬──────────────────────┘
                         │
                  ┌──────▼──────┐
                  │ File Storage │
                  │  (/uploads/) │
                  └─────────────┘
```

### 5.2 Composants Physiques

#### 5.2.1 Frontend

**Web**
- Serveur : Navigateur (Chrome, Edge, Firefox)
- Port : Dynamique (assigned by Flutter)
- Storage : LocalStorage (clés de chiffrement)

**Mobile**
- Android : APK installé sur appareil
- iOS : IPA installé sur appareil
- Storage : Fichiers temporaires + Secure Storage

#### 5.2.2 Backend Principal

- **Serveur** : Machine virtuelle ou serveur dédié
- **Port** : 5000 (développement) / 80/443 (production)
- **Processus** : Flask (dev) / Gunicorn (production)
- **Workers** : 4 workers (recommandé)

#### 5.2.3 STT_API

- **Serveur** : Machine virtuelle ou serveur dédié
- **Port** : 5001 (développement) / 80/443 (production)
- **Processus** : Flask (dev) / Gunicorn (production)
- **Workers** : 2 workers (recommandé, CPU intensif)
- **GPU** : Optionnel (CUDA pour accélération)

#### 5.2.4 Base de Données

- **Type** : PostgreSQL
- **Port** : 5432
- **Storage** : Disque dur SSD recommandé
- **Backup** : Sauvegarde quotidienne

#### 5.2.5 Stockage de Fichiers

- **Type** : Système de fichiers local ou cloud (S3, Azure Blob)
- **Path** : `/uploads/` (local) ou bucket cloud
- **Encryption** : Fichiers déjà chiffrés (AES-256)

### 5.3 Réseau et Communication

#### 5.3.1 Protocoles

- **HTTP/HTTPS** : Communication client-serveur
- **REST** : Architecture API
- **WebSocket** : Optionnel pour notifications en temps réel

#### 5.3.2 Ports

| Service | Port Développement | Port Production |
|---------|-------------------|-----------------|
| Backend Flask | 5000 | 80/443 |
| STT_API | 5001 | 80/443 |
| PostgreSQL | 5432 | 5432 |
| Flutter Web | Dynamique | 80/443 |

#### 5.3.3 CORS

- **Backend** : CORS activé pour `http://localhost:*`
- **STT_API** : CORS activé pour `http://localhost:*`
- **Production** : CORS restreint aux domaines autorisés

### 5.4 Scalabilité

#### 5.4.1 Horizontal Scaling

- **Backend** : Plusieurs instances Flask derrière un load balancer
- **STT_API** : Plusieurs instances pour gérer la charge de transcription
- **Database** : Réplication en lecture (read replicas)

#### 5.4.2 Vertical Scaling

- **STT_API** : GPU pour accélérer la transcription
- **Database** : Plus de RAM et CPU pour les requêtes
- **Storage** : Disque SSD rapide pour les fichiers

---

## 6. Technologies Utilisées

### 6.1 Frontend

#### 6.1.1 Framework Principal

**Flutter** (v3.10.4+)
- Framework multiplateforme (Web, Android, iOS)
- Langage : Dart
- Avantages :
  - Code unique pour toutes les plateformes
  - Performance native
  - Hot reload pour développement rapide

#### 6.1.2 Packages Flutter

| Package | Version | Usage |
|---------|---------|-------|
| `http` | ^1.6.0 | Requêtes HTTP vers l'API |
| `encrypt` | ^5.0.3 | Chiffrement AES-256-CBC |
| `record` | ^5.1.2 | Enregistrement audio |
| `audioplayers` | ^6.1.0 | Lecture de fichiers audio |
| `path_provider` | ^2.1.4 | Accès aux répertoires système |
| `permission_handler` | ^11.3.1 | Gestion des permissions |

#### 6.1.3 Langage

**Dart** (v3.10.4+)
- Langage orienté objet
- Typage statique
- Compilation native et web

### 6.2 Backend Principal

#### 6.2.1 Framework

**Flask** (v2.3.0+)
- Micro-framework Python
- Léger et flexible
- Idéal pour APIs REST

#### 6.2.2 Packages Python

| Package | Version | Usage |
|---------|---------|-------|
| `flask` | 2.3.0+ | Framework web |
| `flask-cors` | 4.0.0+ | Gestion CORS |
| `flask-sqlalchemy` | 3.0+ | ORM pour base de données |
| `python-dotenv` | 1.0+ | Gestion des variables d'environnement |
| `werkzeug` | 2.3.0+ | Utilitaires WSGI |

#### 6.2.3 Base de Données

**PostgreSQL** (v12+)
- Base de données relationnelle
- Support des UUID
- Transactions ACID
- Alternative : SQLite (développement)

**SQLAlchemy** (v2.0+)
- ORM Python
- Abstraction de la base de données
- Migrations automatiques

#### 6.2.4 Langage

**Python** (v3.10+)
- Langage interprété
- Syntaxe claire
- Écosystème riche

### 6.3 STT_API

#### 6.3.1 Framework

**Flask** (v2.3.0+)
- Même stack que le backend principal
- Service indépendant

#### 6.3.2 Packages Python

| Package | Version | Usage |
|---------|---------|-------|
| `faster-whisper` | 0.6.0+ | Transcription audio (Whisper) |
| `torch` | 2.2.0+ | Framework ML (PyTorch) |
| `torchaudio` | 2.2.0+ | Traitement audio |
| `librosa` | 0.10.0+ | Analyse audio |
| `soundfile` | 0.12.1+ | Lecture/écriture audio |
| `numpy` | 1.26.0+ | Calculs numériques |
| `flask-cors` | 4.0.0+ | CORS |

#### 6.3.3 Modèle IA

**Whisper** (OpenAI)
- Modèle de transcription vocale
- Support multi-langues
- Variantes : tiny, small, medium, large-v3
- Utilisé via `faster-whisper` (implémentation optimisée)

### 6.4 Sécurité

#### 6.4.1 Chiffrement

**AES-256-CBC**
- Algorithme : Advanced Encryption Standard
- Taille de clé : 256 bits
- Mode : CBC (Cipher Block Chaining)
- Implémentation : Package `encrypt` (Dart)

#### 6.4.2 Gestion des Clés

- **Clé de chiffrement** : 32 bytes (256 bits)
- **IV (Initialization Vector)** : 16 bytes, unique par message
- **Stockage** : Côté client uniquement (pas sur serveur)

### 6.5 Outils de Développement

#### 6.5.1 Version Control

- **Git** : Contrôle de version
- **GitHub/GitLab** : Hébergement du code

#### 6.5.2 IDE/Éditeurs

- **VS Code** : Éditeur recommandé
- **Android Studio** : Pour développement Android
- **Xcode** : Pour développement iOS (Mac uniquement)

#### 6.5.3 Outils de Test

- **Postman/Insomnia** : Test des APIs
- **curl** : Tests en ligne de commande
- **Flutter DevTools** : Débogage Flutter

### 6.6 Infrastructure

#### 6.6.1 Développement

- **Local** : Tous les services sur machine locale
- **Ports** : 5000 (Backend), 5001 (STT_API), 5432 (PostgreSQL)

#### 6.6.2 Production (Recommandé)

- **Serveur Web** : Nginx ou Apache
- **WSGI Server** : Gunicorn (Python)
- **Reverse Proxy** : Nginx
- **SSL/TLS** : Let's Encrypt (HTTPS)
- **Cloud** : AWS, Azure, Google Cloud (optionnel)

---

## 7. Sécurité

### 7.1 Chiffrement End-to-End (E2EE)

#### 7.1.1 Principe

- **Chiffrement côté client** : Tous les messages sont chiffrés avant l'envoi
- **Serveur aveugle** : Le backend ne peut pas déchiffrer les messages
- **Déchiffrement côté client** : Les messages sont déchiffrés uniquement sur l'appareil du destinataire

#### 7.1.2 Implémentation

```dart
// Chiffrement
EncryptionService.encryptText(plaintext) → {
  encryptedPayload: "base64...",
  iv: "base64..."
}

// Déchiffrement
EncryptionService.decryptText(encryptedPayload, iv) → plaintext
```

#### 7.1.3 Stockage

- **Messages texte** : Payload chiffré en base de données
- **Messages audio** : Fichiers chiffrés dans `/uploads/`
- **IV** : Stocké avec chaque message (nécessaire pour déchiffrement)
- **Aperçus** : Stockés en clair pour affichage dans la liste (optionnel)

### 7.2 Gestion des Clés

#### 7.2.1 Clé de Chiffrement

- **Taille** : 256 bits (32 bytes)
- **Génération** : Côté client
- **Stockage** : LocalStorage (web) ou Secure Storage (mobile)
- **Partage** : Pour prototype, clé partagée (à améliorer en production)

#### 7.2.2 Améliorations Futures

- **Key Exchange** : Protocole Diffie-Hellman ou Signal Protocol
- **Dérivation de clé** : Depuis mot de passe utilisateur (PBKDF2)
- **Clés par conversation** : Chaque conversation a sa propre clé

### 7.3 Transport

#### 7.3.1 HTTPS

- **Développement** : HTTP (localhost)
- **Production** : HTTPS obligatoire (TLS 1.3+)
- **Certificats** : Let's Encrypt (gratuit)

#### 7.3.2 CORS

- **Configuration** : Restreint aux domaines autorisés
- **Headers** : `Access-Control-Allow-Origin` configuré

### 7.4 Authentification

#### 7.4.1 Actuel (Prototype)

- **Méthode** : Email/Mot de passe simple (validation côté client)
- **Header** : `X-User-Id` pour identification des requêtes
- **Session** : Non persistante
- **Token** : Aucun token JWT utilisé actuellement
- **Support préparé** : Le code supporte `Authorization: Bearer <token>` mais aucun token n'est généré ou validé

**Note importante** : JWT n'est **PAS implémenté** dans l'application actuelle. L'architecture supporte les tokens (via `ApiConfig.authToken` et header `Authorization: Bearer`), mais :
- Aucune bibliothèque JWT installée (ni PyJWT côté backend, ni package JWT côté Flutter)
- Aucune génération de tokens
- Aucune validation de tokens
- L'identification se fait uniquement via le header `X-User-Id`

#### 7.4.2 Recommandations Production

- **JWT** : Implémentation de tokens d'authentification (à ajouter)
- **OAuth 2.0** : Intégration avec providers (Google, Apple)
- **2FA** : Authentification à deux facteurs
- **Refresh Tokens** : Renouvellement automatique

### 7.5 Protection des Données

#### 7.5.1 Base de Données

- **Chiffrement au repos** : Optionnel (disque chiffré)
- **Backups chiffrés** : Sauvegardes chiffrées
- **Accès restreint** : Firewall, credentials sécurisés

#### 7.5.2 Fichiers

- **Fichiers chiffrés** : Tous les fichiers audio sont chiffrés
- **Permissions** : Accès restreint aux fichiers
- **Nettoyage** : Suppression automatique des fichiers temporaires

---

## 8. Conclusion

### 8.1 Résumé

VoiceUP est une application de messagerie sécurisée qui combine :
- **Chiffrement end-to-end** pour la confidentialité
- **Transcription automatique** pour la recherche
- **Interface moderne** pour l'expérience utilisateur
- **Architecture modulaire** pour la maintenabilité

### 8.2 Points Forts

✅ **Sécurité** : Chiffrement AES-256-CBC, E2EE
✅ **Fonctionnalités** : Messages texte/vocaux, transcription, recherche
✅ **Performance** : Architecture optimisée, pagination
✅ **Scalabilité** : Architecture modulaire, services indépendants
✅ **Multi-plateforme** : Web, Android, iOS

### 8.3 Améliorations Futures

🔮 **Authentification** : Implémentation de JWT (actuellement non utilisé), OAuth 2.0
🔮 **Key Exchange** : Protocole sécurisé pour échange de clés
🔮 **Notifications** : Push notifications en temps réel
🔮 **Groupes** : Conversations de groupe
🔮 **Médias** : Partage de photos et vidéos
🔮 **Appels** : Appels vocaux et vidéo
🔮 **Cloud Storage** : Stockage cloud pour fichiers
🔮 **Analytics** : Métriques et analytics

### 8.4 Technologies Clés

- **Frontend** : Flutter/Dart
- **Backend** : Flask/Python
- **STT** : Whisper (faster-whisper)
- **Database** : PostgreSQL
- **Chiffrement** : AES-256-CBC

---

**Date du rapport** : Janvier 2026  
**Version** : 1.0.0  
**Auteurs** : Équipe VoiceUP

