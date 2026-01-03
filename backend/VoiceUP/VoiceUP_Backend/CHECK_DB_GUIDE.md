# 📊 Guide : Vérifier les Messages et Transcriptions dans la Base de Données

## Méthode 1 : Utiliser le script Python (Recommandé)

### Commande de base

```bash
cd backend/VoiceUP/VoiceUP_Backend
python check_db.py
```

Le script vous proposera 3 options :
1. **Full database check** - Vérification complète
2. **Check specific transcription** - Vérifier une transcription spécifique
3. **Export transcriptions to JSON** - Exporter toutes les transcriptions

### Option 1 : Vérification complète

```bash
python check_db.py
# Choisir option 1
```

**Affiche :**
- 📊 Résumé (nombre d'utilisateurs, conversations, messages, transcriptions)
- 📨 Détails de tous les messages
- 🗣️ Détails de toutes les transcriptions
- ⚠️ Messages audio sans transcription
- 🔍 Transcriptions orphelines
- 📈 Statistiques
- 💬 Analyse par conversation

### Option 2 : Vérifier une transcription spécifique

```bash
python check_db.py
# Choisir option 2
# Entrer l'ID de la transcription
```

### Option 3 : Exporter les transcriptions

```bash
python check_db.py
# Choisir option 3
# Entrer le nom du fichier (optionnel, défaut: transcriptions_export.json)
```

---

## Méthode 2 : Utiliser SQL directement (PostgreSQL)

### Se connecter à PostgreSQL

```bash
psql -U postgres -d voiceup_db
```

### Requêtes utiles

#### 1. Voir tous les messages avec leurs transcriptions

```sql
SELECT 
    m.id as message_id,
    m.type,
    m."contentPreview",
    m."createdAt",
    t.text as transcription_text,
    t.confidence as transcription_confidence
FROM message m
LEFT JOIN transcription t ON t."messageId" = m.id
ORDER BY m."createdAt" DESC;
```

#### 2. Voir uniquement les messages audio avec transcription

```sql
SELECT 
    m.id,
    m."contentPreview",
    m."createdAt",
    t.text,
    t.confidence
FROM message m
INNER JOIN transcription t ON t."messageId" = m.id
WHERE m.type = 'AUDIO'
ORDER BY m."createdAt" DESC;
```

#### 3. Compter les messages par type

```sql
SELECT 
    type,
    COUNT(*) as count
FROM message
GROUP BY type;
```

#### 4. Voir les transcriptions avec confiance élevée (>90%)

```sql
SELECT 
    m.id as message_id,
    t.text,
    t.confidence
FROM transcription t
JOIN message m ON m.id = t."messageId"
WHERE t.confidence > 0.9
ORDER BY t.confidence DESC;
```

#### 5. Voir les messages audio SANS transcription

```sql
SELECT 
    m.id,
    m."createdAt",
    m."contentPreview"
FROM message m
LEFT JOIN transcription t ON t."messageId" = m.id
WHERE m.type = 'AUDIO' AND t.id IS NULL;
```

#### 6. Voir les dernières transcriptions

```sql
SELECT 
    m.id as message_id,
    u.name as sender,
    t.text,
    t.confidence,
    t."createdAt"
FROM transcription t
JOIN message m ON m.id = t."messageId"
JOIN "user" u ON u.id = m."senderId"
ORDER BY t."createdAt" DESC
LIMIT 10;
```

---

## Méthode 3 : Utiliser SQLite (si vous utilisez SQLite)

Si votre base de données est SQLite (fichier `.db`), utilisez :

```bash
sqlite3 voiceup.db
```

Puis les mêmes requêtes SQL (syntaxe légèrement différente pour les noms de colonnes).

---

## Méthode 4 : Utiliser Python interactif

```python
from app import app
from models import db, Message, Transcription

with app.app_context():
    # Tous les messages avec transcription
    messages = Message.query.all()
    for msg in messages:
        print(f"\nMessage {msg.id} ({msg.type})")
        if msg.transcription:
            print(f"  Transcription: {msg.transcription.text}")
            print(f"  Confidence: {msg.transcription.confidence}")
        else:
            print("  No transcription")
```

---

## Exemples de sortie

### Sortie du script check_db.py

```
======================================================================
DATABASE CHECK - MESSAGES & TRANSCRIPTIONS
======================================================================

📊 SUMMARY:
  Users: 6
  Conversations: 5
  Messages: 12
  Transcriptions: 8
----------------------------------------------------------------------

📨 MESSAGES DETAIL (12 total):
----------------------------------------------------------------------

[1] Message ID: abc-123-def
   Conversation: conv-456
   Sender: Moi-même (user-789)
   Type: AUDIO
   Encrypted: True
   Audio URL: /api/uploads/voice_1234567890.enc
   IV: xyz123...
   Transcription ID: trans-001
   Created: 2024-01-15 10:30:00

🗣️  TRANSCRIPTIONS DETAIL (8 total):
----------------------------------------------------------------------

[1] Transcription ID: trans-001
   Message ID: abc-123-def
   Message Type: AUDIO
   From: Moi-même
   Text: Bonjour, comment allez-vous aujourd'hui ?
   Confidence: 0.95
   Created: 2024-01-15 10:30:01
```

---

## Commandes rapides

### Vérification rapide (résumé seulement)

```bash
cd backend/VoiceUP/VoiceUP_Backend
python -c "from app import app; from models import db, Message, Transcription; app.app_context().push(); print(f'Messages: {Message.query.count()}, Transcriptions: {Transcription.query.count()}')"
```

### Voir les dernières transcriptions

```bash
cd backend/VoiceUP/VoiceUP_Backend
python -c "
from app import app
from models import db, Message, Transcription
with app.app_context():
    trans = Transcription.query.order_by(Transcription.createdAt.desc()).limit(5).all()
    for t in trans:
        print(f'{t.text[:50]}... (conf: {t.confidence:.2%})')
"
```

---

## Dépannage

### Erreur : "Module not found"
Assurez-vous d'être dans le bon répertoire :
```bash
cd backend/VoiceUP/VoiceUP_Backend
```

### Erreur : "Database connection failed"
Vérifiez votre fichier `.env` et que PostgreSQL est démarré.

### Erreur : "No module named 'app'"
Assurez-vous que tous les modules sont installés :
```bash
pip install -r requirements.txt
```

