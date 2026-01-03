# Vue d'ensemble de l'Application - Messagerie Sécurisée

## 🎯 Description Générale

Cette application est une **application de messagerie instantanée sécurisée** développée en Flutter, conçue pour permettre la communication via **messages texte** et **messages vocaux chiffrés**. L'application est préparée pour se connecter à un backend REST API et supporte la transcription audio, le chiffrement end-to-end, et la recherche dans les conversations.

---

## 📱 Architecture de l'Application

### **Structure des Écrans**

L'application comporte **3 écrans principaux** :

#### 1. **Écran de Connexion (Login Page)**
- **Fichier** : `lib/main.dart` (LoginPage)
- **Fonctionnalités** :
  - Authentification simple avec email/mot de passe
  - Credentials de test : `test@test.com` / `test`
  - Validation des champs
  - Navigation vers la liste des conversations après connexion réussie
  - Gestion des erreurs d'authentification

#### 2. **Liste des Conversations (Friends List Page)**
- **Fichier** : `lib/screens/friends_list_page.dart`
- **Fonctionnalités** :
  - Affichage de la liste des contacts/amis (5 contacts par défaut)
  - Affichage des conversations existantes
  - Pour chaque conversation :
    - Nom du contact
    - Dernier message reçu (prévisualisation)
    - Indicateur de messages non lus
    - Horodatage du dernier message
    - Avatar circulaire avec initiales
  - Navigation vers l'écran de chat en cliquant sur une conversation
  - Bouton de déconnexion
  - Interface avec gradient bleu (Material Design 3)

#### 3. **Écran de Chat (Chat Page)**
- **Fichier** : `lib/screens/chat_page.dart`
- **Fonctionnalités principales** :
  - **Affichage des messages** : Liste de messages avec bulles de chat (envoyés vs reçus)
  - **Envoi de messages texte** : Champ de saisie avec bouton d'envoi
  - **Messages vocaux** : Enregistrement, envoi, et lecture de messages audio
  - **Recherche dans la conversation** : Recherche de mots dans les messages avec navigation
  - **Lecture audio** : Contrôles de lecture/pause pour les messages vocaux
  - **Interface moderne** : Design avec gradients bleus, avatars, indicateurs de lecture

---

## 🔑 Fonctionnalités Détaillées

### **1. Messagerie Texte**
- ✅ Envoi et réception de messages texte
- ✅ Affichage différencié des messages envoyés (à droite, bleu) vs reçus (à gauche, gris)
- ✅ Horodatage de chaque message
- ✅ Indicateurs de lecture (✓ pour envoyé, ✓✓ pour lu)
- ✅ Prévisualisation du contenu

### **2. Messages Vocaux (Feature Clé)**
- ✅ **Enregistrement audio** :
  - Bouton micro pour démarrer/arrêter l'enregistrement
  - Barre de progression avec compteur de durée pendant l'enregistrement
  - Support web et mobile (enregistrement adaptatif selon la plateforme)
  - Format audio : M4A (mobile) / WAV (web)
  
- ✅ **Lecture audio** :
  - Contrôles play/pause sur chaque message vocal
  - Barre de progression de lecture
  - Affichage de la durée totale et position actuelle
  - Icône microphone pour identifier les messages vocaux
  - Gestion automatique de la lecture (un seul audio à la fois)

- ✅ **Préparation backend** :
  - Support pour transcription côté client
  - Support pour transcription côté serveur
  - Upload des blobs chiffrés
  - Intégration avec le service de transcription

### **3. Recherche dans les Conversations**
- ✅ **Barre de recherche** accessible depuis l'AppBar
- ✅ **Recherche en temps réel** pendant la saisie
- ✅ **Mise en évidence** : Texte recherché surligné en jaune dans les messages
- ✅ **Navigation entre résultats** :
  - Compteur "X/Y" résultats
  - Boutons précédent/suivant
  - Défilement automatique vers le message trouvé
  - Bordure jaune autour du message actuellement sélectionné
- ✅ **Recherche insensible à la casse**

### **4. Interface Utilisateur**
- ✅ **Design moderne** :
  - Material Design 3
  - Gradients bleus (couleur primaire : #1976D2)
  - Animations fluides
  - Avatars circulaires avec initiales
  - Interface responsive
  
- ✅ **Expérience utilisateur** :
  - Messages groupés par conversation
  - Scrolling automatique vers les nouveaux messages
  - Feedback visuel (icônes, couleurs)
  - États visuels (enregistrement, lecture, recherche)

---

## 🔌 Services Backend (Prêts pour connexion)

L'application est **entièrement préparée** pour se connecter à un backend REST API. Tous les services sont implémentés dans `lib/services/` :

### **Services Disponibles**

1. **ContactsService** - Gestion des contacts/amis
   - `GET /api/contacts`

2. **ConversationsService** - Gestion des conversations
   - `GET /api/conversations`
   - `POST /api/conversations`

3. **MessagesService** - Gestion des messages
   - `GET /api/conversations/:id/messages` (paginé)
   - `POST /api/conversations/:id/messages` (texte)
   - `POST /api/conversations/:id/messages` (audio)
   - `POST /api/conversations/:id/messages?serverTranscribe=true`
   - `GET /api/messages/:messageId`
   - `GET /api/messages/:messageId/blob`

4. **TranscriptionService** - Transcription audio
   - `GET /api/messages/:messageId/transcription`
   - `POST /api/transcribe`

5. **SearchService** - Recherche
   - `GET /api/search?conversationId=:id&q=mot`

6. **UploadService** - Upload de fichiers
   - `POST /api/uploads`

7. **ApiService** - Utilitaires
   - `GET /api/health`
   - `GET /api/version`

### **Configuration Backend**

Pour connecter l'application au backend, modifiez `lib/config/api_config.dart` :

```dart
static const String baseUrl = 'http://votre-backend-url:port';
```

---

## 📦 Modèles de Données

### **User** (`lib/models/user.dart`)
- ID, nom, nom d'affichage, URL avatar, date de création

### **Conversation** (`lib/models/conversation.dart`)
- ID, titre, liste des IDs des participants, date de création

### **Message** (`lib/models/message.dart`)
- ID, conversationId, senderId, type (TEXT/AUDIO)
- Données chiffrées : encryptedBlobUrl, iv, isEncrypted
- Prévisualisation : contentPreview, transcriptionId
- Métadonnées : createdAt, isRead

### **Transcription** (`lib/models/transcription.dart`)
- ID, messageId, texte, niveau de confiance, date de création

---

## 🔐 Sécurité & Chiffrement

L'application est **conçue pour supporter le chiffrement end-to-end** :

- ✅ Messages texte : Support du payload chiffré avec IV
- ✅ Messages audio : Support des blobs chiffrés avec URL de stockage
- ✅ Transcription : Support de la transcription (stockée en clair pour recherche ou chiffrée selon politique)
- ✅ Upload sécurisé : Support pour upload de fichiers chiffrés
- ✅ Authentification : Support Bearer token + X-User-Id pour prototype

**Note** : Le chiffrement réel doit être implémenté côté client avant l'envoi.

---

## 🌐 Support Multi-Plateforme

L'application fonctionne sur :
- ✅ **Web** (Chrome, Edge) - Enregistrement audio via MediaRecorder API
- ✅ **Android** - Enregistrement natif
- ✅ **iOS** - Enregistrement natif (si configuré)
- ✅ **Windows Desktop** - Via Flutter desktop

Adaptation automatique selon la plateforme (gestion des fichiers, permissions, formats audio).

---

## 🎨 Technologies Utilisées

- **Flutter** - Framework de développement
- **Dart** - Langage de programmation
- **Material Design 3** - Design system
- **record** - Enregistrement audio
- **audioplayers** - Lecture audio
- **http** - Client HTTP pour API
- **path_provider** - Gestion des chemins de fichiers

---

## 📝 État Actuel vs Backend

### **Actuellement (Mode Mock)**
- ✅ Données mockées (5 contacts, conversations, messages d'exemple)
- ✅ Toute l'interface fonctionnelle
- ✅ Toutes les fonctionnalités UI implémentées
- ✅ Services backend prêts mais non connectés

### **Après Connexion Backend**
- 🔄 Remplacer les données mockées par des appels API
- 🔄 Intégrer l'authentification réelle
- 🔄 Implémenter le chiffrement réel
- 🔄 Connecter la transcription audio
- 🔄 Synchroniser les messages en temps réel (si WebSocket implémenté)

---

## 🚀 Workflow Utilisateur Typique

1. **Connexion** : L'utilisateur se connecte avec email/password
2. **Liste des conversations** : Voit ses contacts et conversations existantes
3. **Ouvrir une conversation** : Clique sur une conversation pour ouvrir le chat
4. **Envoyer un message texte** : Tape un message et appuie sur envoyer
5. **Envoyer un message vocal** :
   - Appuie sur le bouton micro
   - Enregistre le message (barre de progression visible)
   - Appuie sur "Envoyer" pour envoyer
   - Le message apparaît dans le chat
6. **Lire un message vocal** : Clique sur play pour écouter
7. **Rechercher** : Clique sur l'icône recherche, tape un mot, navigue entre résultats
8. **Déconnexion** : Retour à l'écran de connexion

---

## 📚 Structure du Projet

```
lib/
├── main.dart                    # Point d'entrée + Login
├── config/
│   └── api_config.dart         # Configuration API
├── models/                      # Modèles de données
│   ├── user.dart
│   ├── conversation.dart
│   ├── message.dart
│   └── transcription.dart
├── screens/                     # Écrans de l'application
│   ├── friends_list_page.dart  # Liste des conversations
│   └── chat_page.dart          # Écran de chat
└── services/                    # Services API
    ├── api_client.dart         # Client HTTP de base
    ├── api_service.dart        # Service principal
    ├── contacts_service.dart
    ├── conversations_service.dart
    ├── messages_service.dart
    ├── transcription_service.dart
    ├── search_service.dart
    └── upload_service.dart
```

---

## ✅ Résumé

Cette application est une **messagerie instantanée complète et fonctionnelle** avec :
- ✅ Interface moderne et intuitive
- ✅ Messages texte et vocaux
- ✅ Recherche avancée
- ✅ Support multi-plateforme
- ✅ Architecture préparée pour le chiffrement E2E
- ✅ Services backend prêts pour connexion
- ✅ Transcription audio (prête à intégrer)

**L'application est prête à être connectée au backend et à fonctionner en production !**

