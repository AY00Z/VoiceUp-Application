# 📱 Lancer l'application Flutter avec des dimensions mobiles

## Méthode 1 : Utiliser Chrome DevTools (Recommandé pour le développement)

### Étape 1 : Lancer l'application en mode web

```bash
cd frontend
flutter run -d chrome
```

### Étape 2 : Ouvrir Chrome DevTools

1. Dans Chrome, appuyez sur **F12** ou **Ctrl+Shift+I** (Windows/Linux) ou **Cmd+Option+I** (Mac)
2. Cliquez sur l'icône **Toggle device toolbar** (ou appuyez sur **Ctrl+Shift+M** / **Cmd+Shift+M**)

### Étape 3 : Sélectionner un appareil mobile

Dans la barre d'outils DevTools :
- Cliquez sur le menu déroulant "Responsive"
- Sélectionnez un appareil (ex: **iPhone 12 Pro**, **Pixel 5**, **Galaxy S20**, etc.)
- Ou créez une taille personnalisée (ex: **375x812** pour iPhone)

### Dimensions mobiles courantes :

- **iPhone 12/13/14 Pro** : 390 x 844
- **iPhone SE** : 375 x 667
- **Pixel 5** : 393 x 851
- **Galaxy S20** : 360 x 800
- **iPad Mini** : 768 x 1024

## Méthode 2 : Utiliser les flags Flutter (Dimensions personnalisées)

### Créer un script de lancement

**Windows (PowerShell) :**

Créez `run_mobile.ps1` :

```powershell
cd frontend
flutter run -d chrome --web-renderer html --web-browser-flag "--window-size=375,812"
```

**Linux/Mac :**

Créez `run_mobile.sh` :

```bash
#!/bin/bash
cd frontend
flutter run -d chrome --web-renderer html --web-browser-flag "--window-size=375,812"
chmod +x run_mobile.sh
```

### Dimensions personnalisées

Modifiez `--window-size=WIDTH,HEIGHT` :
- `--window-size=375,812` : iPhone 12/13/14
- `--window-size=390,844` : iPhone 12 Pro Max
- `--window-size=360,800` : Android standard
- `--window-size=393,851` : Pixel 5

## Méthode 3 : Utiliser un émulateur Android/iOS (Vraie expérience mobile)

### Android

1. **Installer Android Studio**
2. **Créer un AVD (Android Virtual Device)** :
   - Tools → Device Manager
   - Create Device
   - Sélectionner un appareil (ex: Pixel 5)
   - Sélectionner une version Android (ex: API 33)
3. **Lancer l'émulateur** :
   ```bash
   flutter run
   # Sélectionner l'émulateur Android
   ```

### iOS (Mac uniquement)

1. **Installer Xcode**
2. **Ouvrir un simulateur iOS** :
   ```bash
   open -a Simulator
   ```
3. **Lancer l'application** :
   ```bash
   flutter run
   # Sélectionner le simulateur iOS
   ```

## Méthode 4 : Utiliser Flutter avec des dimensions fixes dans le code

Ajoutez dans `main.dart` :

```dart
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

void main() {
  // Forcer les dimensions mobiles en mode web
  if (kIsWeb) {
    // Définir la taille de la fenêtre (nécessite window_manager ou similaire)
    // Ou utiliser MediaQuery pour simuler
  }
  runApp(const MyApp());
}
```

## Méthode 5 : Utiliser un navigateur avec extension (Chrome)

### Extension "Window Resizer"

1. Installez l'extension Chrome "Window Resizer"
2. Lancez l'app Flutter
3. Cliquez sur l'extension et sélectionnez une taille mobile (ex: 375x812)

## Recommandation

Pour le développement, utilisez **Méthode 1** (Chrome DevTools) car :
- ✅ Facile à activer/désactiver
- ✅ Permet de tester différentes tailles rapidement
- ✅ Outils de débogage intégrés
- ✅ Pas besoin de configuration supplémentaire

Pour les tests finaux, utilisez **Méthode 3** (émulateur) pour une expérience plus réaliste.

## Commandes rapides

### Lancer avec dimensions iPhone 12
```bash
cd frontend
flutter run -d chrome --web-browser-flag "--window-size=390,844"
```

### Lancer avec dimensions Android standard
```bash
cd frontend
flutter run -d chrome --web-browser-flag "--window-size=360,800"
```

### Lancer et ouvrir DevTools automatiquement
```bash
cd frontend
flutter run -d chrome
# Puis appuyez sur F12 dans Chrome
```

