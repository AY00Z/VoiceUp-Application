# 🚀 Guide d'Installation et Démarrage - Backend & Frontend

Ce guide vous permet d'installer et de démarrer le backend Flask et le frontend Flutter.

---

## 📋 Prérequis

### Backend (Python)
- ✅ Python 3.8+ installé
- ✅ PostgreSQL installé et en cours d'exécution
- ✅ pip (gestionnaire de packages Python)

### Frontend (Flutter)
- ✅ Flutter SDK installé
- ✅ Dart SDK (inclus avec Flutter)

---

## 🔧 Partie 1 : Installation du Backend Flask

### 1. Naviguer vers le dossier backend

```powershell
cd "C:\Users\aya20\Desktop\3eme ENSI\mobile\backend\VoiceUP\VoiceUP_Backend"
```

### 2. Installer les dépendances Python

```powershell
pip install -r requirements.txt
```

**Dépendances installées :**
- Flask==3.0.0
- Flask-SQLAlchemy==3.1.1
- Flask-Migrate==4.0.5
- psycopg2-binary==2.9.9
- flask-cors==4.0.0
- python-dotenv==1.0.0

### 3. Configurer la base de données PostgreSQL

**a) Créer la base de données :**
- Ouvrir pgAdmin 4 ou utiliser la ligne de commande
- Créer une nouvelle base de données nommée `voiceup_db`

**b) Créer le fichier `.env` :**
Dans le dossier `VoiceUP_Backend`, créer un fichier `.env` avec :

```env
DATABASE_URL=postgresql://postgres:VOTRE_MOT_DE_PASSE@localhost:5432/voiceup_db
UPLOAD_FOLDER=uploads
```

⚠️ **Important** : Remplacer `VOTRE_MOT_DE_PASSE` par votre mot de passe PostgreSQL.

### 4. Créer les tables de la base de données

```powershell
python app.py
```

Laissez le serveur démarrer (les tables seront créées automatiquement). Vous verrez quelque chose comme :
```
 * Running on http://127.0.0.1:5000
```

### 5. Peupler la base de données avec des données de test

Dans un **nouveau terminal** (gardez le serveur Flask en cours d'exécution) :

```powershell
cd "C:\Users\aya20\Desktop\3eme ENSI\mobile\backend\VoiceUP\VoiceUP_Backend"
python seed.py
```

Cela créera 5 contacts fictifs dans la base de données.

### 6. Vérifier que le backend fonctionne

Ouvrir un navigateur et aller à : http://127.0.0.1:5000/api/health

Vous devriez voir une réponse confirmant que le serveur fonctionne.

---

## 📱 Partie 2 : Configuration et Démarrage du Frontend Flutter

### 1. Naviguer vers le dossier frontend

```powershell
cd "C:\Users\aya20\Desktop\3eme ENSI\mobile\frontend"
```

### 2. Installer les dépendances Flutter

```powershell
flutter pub get
```

### 3. Configurer l'URL du backend

Éditer le fichier `lib/config/api_config.dart` et modifier l'URL du backend :

```dart
static const String baseUrl = 'http://127.0.0.1:5000';
```

**Note** : Le backend Flask utilise le port 5000 par défaut, pas 3000.

### 4. Lancer l'application Flutter

**Option A - Web (Edge/Chrome) :**
```powershell
flutter run -d edge
```
ou
```powershell
flutter run -d chrome
```

**Option B - Windows Desktop :**
```powershell
flutter run -d windows
```

**Option C - Android (si émulateur/device connecté) :**
```powershell
flutter run -d android
```

---

## ✅ Vérification Complète

### Backend ✅
- ✅ Serveur Flask en cours d'exécution sur http://127.0.0.1:5000
- ✅ Base de données PostgreSQL créée et configurée
- ✅ Tables créées automatiquement
- ✅ 5 contacts fictifs ajoutés via `seed.py`
- ✅ Dossier `uploads/` créé pour les fichiers audio

### Frontend ✅
- ✅ Dépendances Flutter installées (`flutter pub get`)
- ✅ URL backend configurée dans `api_config.dart` (http://127.0.0.1:5000)
- ✅ Application Flutter lancée

---

## 🔍 Dépannage

### Erreur : "Module not found" (Python)
**Solution** : Vérifier que toutes les dépendances sont installées
```powershell
pip install -r requirements.txt
```

### Erreur : "Could not connect to database" (PostgreSQL)
**Solutions** :
1. Vérifier que PostgreSQL est démarré
2. Vérifier le fichier `.env` (mot de passe correct)
3. Vérifier que la base de données `voiceup_db` existe

### Erreur : "Port already in use" (Flask)
**Solution** : Le port 5000 est peut-être déjà utilisé. Vérifier dans `app.py` et changer le port si nécessaire.

### Erreur : "Failed to connect to backend" (Flutter)
**Solutions** :
1. Vérifier que le backend Flask est en cours d'exécution
2. Vérifier l'URL dans `lib/config/api_config.dart`
3. Pour web, utiliser `http://127.0.0.1:5000` (pas `localhost`)

### Erreur : "CORS error" (Web)
**Solution** : Le backend doit avoir `flask-cors` installé et configuré (déjà dans requirements.txt)

---

## 📝 Notes Importantes

1. **Backend** : Garder le serveur Flask en cours d'exécution pendant que vous utilisez l'application Flutter
2. **Base de données** : Ne pas supprimer le dossier `uploads/` - il contient les fichiers audio chiffrés
3. **Ports** :
   - Backend Flask : 5000 (par défaut)
   - Frontend Flutter : Port aléatoire pour web (géré automatiquement)
4. **Authentification** : Pour le prototype, utiliser l'en-tête `X-User-Id: me` (configuré par défaut)

---

## 🎯 Commandes Rapides (Résumé)

### Backend
```powershell
# 1. Aller dans le dossier backend
cd "C:\Users\aya20\Desktop\3eme ENSI\mobile\backend\VoiceUP\VoiceUP_Backend"

# 2. Installer les dépendances
pip install -r requirements.txt

# 3. Créer .env avec DATABASE_URL et UPLOAD_FOLDER

# 4. Démarrer le serveur
python app.py

# 5. Dans un nouveau terminal, peupler la DB
python seed.py
```

### Frontend
```powershell
# 1. Aller dans le dossier frontend
cd "C:\Users\aya20\Desktop\3eme ENSI\mobile\frontend"

# 2. Installer les dépendances
flutter pub get

# 3. Modifier lib/config/api_config.dart (baseUrl = 'http://127.0.0.1:5000')

# 4. Lancer l'application
flutter run -d edge
```

---

**Bonne chance ! 🚀**


