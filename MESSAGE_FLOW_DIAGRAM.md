# Diagramme de Séquence - Flux des Messages VoiceUP

## 1. Envoi d'un Message Texte

```
┌─────────┐      ┌──────────────┐      ┌─────────────┐      ┌──────────┐      ┌──────────┐
│  User   │      │ ChatPage     │      │ Encryption  │      │ API      │      │ Backend  │
│         │      │              │      │ Service     │      │ Service  │      │ Flask    │
└────┬────┘      └──────┬───────┘      └──────┬──────┘      └────┬─────┘      └────┬─────┘
     │                  │                      │                  │                 │
     │ 1. Tape message │                      │                  │                 │
     │─────────────────>│                      │                  │                 │
     │                  │                      │                  │                 │
     │                  │ 2. encryptText()    │                  │                 │
     │                  │────────────────────>│                  │                 │
     │                  │                      │                  │                 │
     │                  │ 3. encryptedPayload  │                  │                 │
     │                  │    + IV              │                  │                 │
     │                  │<─────────────────────│                  │                 │
     │                  │                      │                  │                 │
     │                  │ 4. sendTextMessage() │                  │                 │
     │                  │──────────────────────┼─────────────────>│                 │
     │                  │                      │                  │                 │
     │                  │                      │                  │ POST /api/      │
     │                  │                      │                  │ conversations/  │
     │                  │                      │                  │ {id}/messages   │
     │                  │                      │                  │────────────────>│
     │                  │                      │                  │                 │
     │                  │                      │                  │                 │ 5. Save to DB
     │                  │                      │                  │                 │    (encrypted)
     │                  │                      │                  │                 │
     │                  │                      │                  │ 6. Message      │
     │                  │                      │                  │    created     │
     │                  │                      │                  │<────────────────│
     │                  │                      │                  │                 │
     │                  │ 7. Update UI        │                  │                 │
     │                  │<─────────────────────┼──────────────────│                 │
     │                  │                      │                  │                 │
```

## 2. Envoi d'un Message Vocal (Audio)

```
┌─────────┐      ┌──────────────┐      ┌─────────────┐      ┌──────────┐      ┌──────────┐      ┌──────────┐
│  User   │      │ ChatPage     │      │ Encryption  │      │ Upload   │      │ API      │      │ Backend  │
│         │      │              │      │ Service     │      │ Service  │      │ Service  │      │ Flask    │
└────┬────┘      └──────┬───────┘      └──────┬──────┘      └────┬─────┘      └────┬─────┘      └────┬─────┘
     │                  │                      │                  │                 │                 │
     │ 1. Start record  │                      │                  │                 │                 │
     │─────────────────>│                      │                  │                 │                 │
     │                  │                      │                  │                 │                 │
     │ 2. Stop record   │                      │                  │                 │                 │
     │─────────────────>│                      │                  │                 │                 │
     │                  │                      │                  │                 │                 │
     │                  │ 3. readFileAsBytes() │                  │                 │                 │
     │                  │─────────────────────>│                  │                 │                 │
     │                  │                      │                  │                 │                 │
     │                  │ 4. audioBytes        │                  │                 │                 │
     │                  │<─────────────────────│                  │                 │                 │
     │                  │                      │                  │                 │                 │
     │                  │ 5. encryptBinary()   │                  │                 │                 │
     │                  │─────────────────────>│                  │                 │                 │
     │                  │                      │                  │                 │                 │
     │                  │ 6. encryptedBytes   │                  │                 │                 │
     │                  │    + IV              │                  │                 │                 │
     │                  │<─────────────────────│                  │                 │                 │
     │                  │                      │                  │                 │                 │
     │                  │ 7. uploadAudioBlob() │                  │                 │                 │
     │                  │──────────────────────┼─────────────────>│                 │                 │
     │                  │                      │                  │                 │                 │
     │                  │                      │                  │ POST /api/      │                 │
     │                  │                      │                  │ uploads         │                 │
     │                  │                      │                  │────────────────>│                 │
     │                  │                      │                  │                 │                 │
     │                  │                      │                  │                 │ 8. Save file    │
     │                  │                      │                  │                 │    to uploads/  │
     │                  │                      │                  │                 │                 │
     │                  │                      │                  │ 9. Return URL   │                 │
     │                  │                      │                  │<────────────────│                 │
     │                  │                      │                  │                 │                 │
     │                  │ 10. sendAudioMessage│                  │                 │                 │
     │                  │───────────────────────┼──────────────────┼────────────────>│                 │
     │                  │                      │                  │                 │                 │
     │                  │                      │                  │                 │ POST /api/      │
     │                  │                      │                  │                 │ conversations/  │
     │                  │                      │                  │                 │ {id}/messages   │
     │                  │                      │                  │                 │────────────────>│
     │                  │                      │                  │                 │                 │
     │                  │                      │                  │                 │                 │ 11. Save to DB
     │                  │                      │                  │                 │                 │    (encrypted URL)
     │                  │                      │                  │                 │                 │
     │                  │                      │                  │                 │ 12. Message     │
     │                  │                      │                  │                 │    created       │
     │                  │                      │                  │                 │<────────────────│
     │                  │                      │                  │                 │                 │
     │                  │ 13. Update UI        │                  │                 │                 │
     │                  │<─────────────────────┼──────────────────┼─────────────────│                 │
     │                  │                      │                  │                 │                 │
```

## 3. Récupération et Affichage des Messages

```
┌─────────┐      ┌──────────────┐      ┌──────────┐      ┌──────────┐      ┌─────────────┐
│  User   │      │ ChatPage     │      │ API      │      │ Backend  │      │ Encryption  │
│         │      │              │      │ Service  │      │ Flask    │      │ Service     │
└────┬────┘      └──────┬───────┘      └────┬─────┘      └────┬─────┘      └────┬────────┘
     │                  │                   │                 │                 │
     │ 1. Open chat     │                   │                 │                 │
     │─────────────────>│                   │                 │                 │
     │                  │                   │                 │                 │
     │                  │ 2. getMessages()  │                 │                 │
     │                  │───────────────────>│                 │                 │
     │                  │                   │                 │                 │
     │                  │                   │ GET /api/       │                 │
     │                  │                   │ conversations/  │                 │
     │                  │                   │ {id}/messages   │                 │
     │                  │                   │────────────────>│                 │
     │                  │                   │                 │                 │
     │                  │                   │                 │ 3. Query DB     │
     │                  │                   │                 │    (encrypted)  │
     │                  │                   │                 │                 │
     │                  │                   │ 4. Messages    │                 │
     │                  │                   │    (encrypted)  │                 │
     │                  │                   │<────────────────│                 │
     │                  │                   │                 │                 │
     │                  │ 5. For each msg:  │                 │                 │
     │                  │    decryptText() │                 │                 │
     │                  │───────────────────────────────────────────────────────>│
     │                  │                   │                 │                 │
     │                  │ 6. Decrypted text │                 │                 │
     │                  │<───────────────────────────────────────────────────────│
     │                  │                   │                 │                 │
     │                  │ 7. Display in UI │                 │                 │
     │                  │<───────────────────│                 │                 │
     │                  │                   │                 │                 │
```

## 4. Lecture d'un Message Vocal (Playback)

```
┌─────────┐      ┌──────────────┐      ┌──────────┐      ┌──────────┐      ┌─────────────┐      ┌──────────┐
│  User   │      │ ChatPage     │      │ HTTP     │      │ Backend  │      │ Encryption  │      │ Audio    │
│         │      │              │      │ Client   │      │ Flask    │      │ Service     │      │ Player   │
└────┬────┘      └──────┬───────┘      └────┬─────┘      └────┬─────┘      └────┬────────┘      └────┬─────┘
     │                  │                   │                 │                 │                    │
     │ 1. Click play    │                   │                 │                 │                    │
     │─────────────────>│                   │                 │                 │                    │
     │                  │                   │                 │                 │                    │
     │                  │ 2. Get encrypted  │                 │                 │                    │
     │                  │    blob URL        │                 │                 │                    │
     │                  │                   │                 │                 │                    │
     │                  │ 3. GET /api/      │                 │                 │                    │
     │                  │    uploads/{file} │                 │                 │                    │
     │                  │───────────────────┼─────────────────>│                 │                    │
     │                  │                   │                 │                 │                    │
     │                  │                   │                 │ 4. Read file    │                    │
     │                  │                   │                 │    from disk    │                    │
     │                  │                   │                 │                 │                    │
     │                  │ 5. encryptedBytes │                 │                 │                    │
     │                  │<───────────────────┼─────────────────│                 │                    │
     │                  │                   │                 │                 │                    │
     │                  │ 6. decryptBinary()│                 │                 │                    │
     │                  │───────────────────────────────────────────────────────>│                    │
     │                  │                   │                 │                 │                    │
     │                  │ 7. decryptedBytes │                 │                 │                    │
     │                  │<───────────────────────────────────────────────────────│                    │
     │                  │                   │                 │                 │                    │
     │                  │ 8. Create blob    │                 │                 │                    │
     │                  │    URL (web)       │                 │                 │                    │
     │                  │                   │                 │                 │                    │
     │                  │ 9. Play audio     │                 │                 │                    │
     │                  │───────────────────────────────────────────────────────────────────────────>│
     │                  │                   │                 │                 │                    │
     │                  │ 10. Audio plays   │                 │                 │                    │
     │                  │<───────────────────────────────────────────────────────────────────────────│
     │                  │                   │                 │                 │                    │
```

## 5. Chargement de la Liste des Amis (Friends List)

```
┌─────────┐      ┌──────────────┐      ┌──────────┐      ┌──────────┐      ┌──────────┐
│  User   │      │FriendsList   │      │ API      │      │ Backend  │      │ Messages │
│         │      │Page          │      │ Service  │      │ Flask    │      │ Service  │
└────┬────┘      └──────┬───────┘      └────┬─────┘      └────┬─────┘      └────┬─────┘
     │                  │                   │                 │                 │
     │ 1. Open page     │                   │                 │                 │
     │─────────────────>│                   │                 │                 │
     │                  │                   │                 │                 │
     │                  │ 2. getContacts()  │                 │                 │
     │                  │───────────────────>│                 │                 │
     │                  │                   │                 │                 │
     │                  │                   │ GET /api/       │                 │
     │                  │                   │ contacts        │                 │
     │                  │                   │────────────────>│                 │
     │                  │                   │                 │                 │
     │                  │                   │ 3. All users   │                 │
     │                  │                   │<────────────────│                 │
     │                  │                   │                 │                 │
     │                  │ 4. Find "Moi-même"│                 │                 │
     │                  │    get UUID       │                 │                 │
     │                  │                   │                 │                 │
     │                  │ 5. getConversations│                 │                 │
     │                  │───────────────────>│                 │                 │
     │                  │                   │                 │                 │
     │                  │                   │ GET /api/       │                 │
     │                  │                   │ conversations   │                 │
     │                  │                   │────────────────>│                 │
     │                  │                   │                 │                 │
     │                  │                   │ 6. All convs    │                 │
     │                  │                   │<────────────────│                 │
     │                  │                   │                 │                 │
     │                  │ 7. For each conv:  │                 │                 │
     │                  │    getMessages()   │                 │                 │
     │                  │───────────────────────────────────────────────────────>│
     │                  │                   │                 │                 │
     │                  │                   │                 │                 │ GET /api/
     │                  │                   │                 │                 │ conversations/
     │                  │                   │                 │                 │ {id}/messages
     │                  │                   │                 │                 │────────────────>│
     │                  │                   │                 │                 │                 │
     │                  │                   │                 │                 │ 8. Last message │
     │                  │                   │                 │                 │<────────────────│
     │                  │                   │                 │                 │                 │
     │                  │ 9. Display list   │                 │                 │                 │
     │                  │<───────────────────│                 │                 │                 │
     │                  │                   │                 │                 │                 │
```

## Résumé du Flux

### **Chiffrement (Encryption)**
- **Texte**: Chiffré avec AES-256-CBC côté client avant envoi
- **Audio**: Enregistré → Chiffré → Uploadé → URL stockée en DB

### **Stockage (Storage)**
- **Messages texte**: Payload chiffré stocké directement en DB
- **Messages audio**: Fichier chiffré stocké dans `/uploads/`, URL en DB

### **Déchiffrement (Decryption)**
- **Texte**: Déchiffré côté client lors de l'affichage
- **Audio**: Téléchargé → Déchiffré → Création blob URL → Lecture

### **Sécurité**
- Tous les messages sont chiffrés avant envoi
- La clé de chiffrement est partagée (prototype)
- L'IV (Initialization Vector) est unique pour chaque message
- Les fichiers audio sont chiffrés avant upload

