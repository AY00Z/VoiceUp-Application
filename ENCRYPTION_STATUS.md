# État du Chiffrement dans la Base de Données

## ✅ OUI - Les messages SONT chiffrés dans la base de données

### **Messages Texte (TEXT)**

**Ce qui est chiffré:**
- ✅ **`encryptedPayload`** - Le contenu du message est **chiffré** (AES-256-CBC, base64)
- ✅ **`iv`** - L'IV (Initialization Vector) est stocké séparément

**Ce qui n'est PAS chiffré:**
- ❌ **`contentPreview`** - Aperçu en clair pour l'affichage dans la liste (ex: "Hello", "Voice message")
- ❌ **Métadonnées** - `id`, `conversationId`, `senderId`, `type`, `createdAt` sont en clair

**Exemple dans la DB:**
```sql
encryptedPayload: "U2FsdGVkX1+vupppZksvRf5pq5g5XkFy..."  ← CHIFFRÉ
iv: "dGhpc2lzYW5pdmVjdG9y"                              ← IV (nécessaire pour déchiffrer)
contentPreview: "Hello"                                  ← EN CLAIR (prévisualisation)
```

### **Messages Audio (AUDIO)**

**Ce qui est chiffré:**
- ✅ **Fichier audio** - Le fichier audio est **chiffré** et stocké dans `/uploads/`
- ✅ **`encryptedBlobUrl`** - URL vers le fichier chiffré (ex: `/api/uploads/abc123.enc`)
- ✅ **`iv`** - L'IV est stocké avec le message

**Ce qui n'est PAS chiffré:**
- ❌ **`contentPreview`** - Généralement "Voice message" (en clair)
- ❌ **Métadonnées** - `id`, `conversationId`, `senderId`, `type`, `createdAt` sont en clair

**Exemple dans la DB:**
```sql
encryptedBlobUrl: "/api/uploads/17880720-6e3d-4c47-abfb-4b584b0336c8.enc"  ← URL vers fichier CHIFFRÉ
iv: "dGhpc2lzYW5pdmVjdG9y"                                                 ← IV
contentPreview: "Voice message"                                             ← EN CLAIR
```

## Flux de Chiffrement

### **Envoi Message Texte**

```
1. User tape: "Hello"
   ↓
2. Frontend: encryptText("Hello")
   → encryptedPayload: "U2FsdGVkX1+vupppZksvRf5pq5g5XkFy..." (chiffré)
   → iv: "dGhpc2lzYW5pdmVjdG9y"
   ↓
3. Backend reçoit:
   - encryptedPayload (chiffré) ✅
   - iv ✅
   - plaintextPreview: "Hello" (en clair pour preview) ❌
   ↓
4. Base de données stocke:
   - encryptedPayload: "U2FsdGVkX1+vupppZksvRf5pq5g5XkFy..." ✅ CHIFFRÉ
   - iv: "dGhpc2lzYW5pdmVjdG9y" ✅
   - contentPreview: "Hello" ❌ EN CLAIR
```

### **Envoi Message Audio**

```
1. User enregistre audio
   ↓
2. Frontend: encryptBinary(audioBytes)
   → encryptedBytes (chiffré)
   → iv
   ↓
3. Upload fichier chiffré → /api/uploads
   → Fichier stocké: uploads/abc123.enc ✅ CHIFFRÉ
   ↓
4. Backend crée message avec:
   - encryptedBlobUrl: "/api/uploads/abc123.enc" ✅
   - iv ✅
   - contentPreview: "Voice message" ❌ EN CLAIR
   ↓
5. Base de données stocke:
   - encryptedBlobUrl: "/api/uploads/abc123.enc" ✅ (URL vers fichier CHIFFRÉ)
   - iv ✅
   - contentPreview: "Voice message" ❌ EN CLAIR
```

## Lecture des Messages

### **Message Texte**

```
1. Backend retourne depuis DB:
   - encryptedPayload: "U2FsdGVkX1+vupppZksvRf5pq5g5XkFy..." ✅ CHIFFRÉ
   - iv: "dGhpc2lzYW5pdmVjdG9y" ✅
   ↓
2. Frontend: decryptText(encryptedPayload, iv)
   → "Hello" (déchiffré)
   ↓
3. Affichage dans l'UI
```

### **Message Audio**

```
1. Backend retourne depuis DB:
   - encryptedBlobUrl: "/api/uploads/abc123.enc" ✅
   - iv ✅
   ↓
2. Frontend télécharge le fichier chiffré
   ↓
3. Frontend: decryptBinary(encryptedBytes, iv)
   → audioBytes (déchiffré)
   ↓
4. Création blob URL et lecture
```

## Résumé

| Type | Contenu Principal | Preview | Fichier Audio |
|------|------------------|---------|---------------|
| **TEXT** | ✅ **CHIFFRÉ** (`encryptedPayload`) | ❌ En clair (`contentPreview`) | N/A |
| **AUDIO** | ✅ **CHIFFRÉ** (fichier dans `/uploads/`) | ❌ En clair (`contentPreview`) | ✅ **CHIFFRÉ** |

## Sécurité

### ✅ **Points Forts:**
- Le contenu réel des messages est chiffré
- Chaque message a un IV unique
- Les fichiers audio sont chiffrés avant stockage
- Le déchiffrement se fait uniquement côté client

### ⚠️ **Points d'Attention:**
- `contentPreview` est en clair (nécessaire pour l'UI, mais révèle un aperçu)
- Les métadonnées (qui, quand, où) sont en clair
- La clé de chiffrement est partagée (prototype)
- En production, il faudrait un système de key exchange

## Conclusion

**OUI, les messages sont chiffrés dans la base de données:**
- ✅ Le contenu texte est chiffré dans `encryptedPayload`
- ✅ Les fichiers audio sont chiffrés dans `/uploads/`
- ❌ Seul `contentPreview` est en clair (pour l'affichage dans la liste)

Pour voir le contenu réel, il faut:
1. Avoir accès à la base de données
2. Connaître la clé de chiffrement
3. Déchiffrer avec l'IV correspondant

