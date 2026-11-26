# AgriSmart

AgriSmart est une application Flutter de gestion agricole pour suivre les zones,
la météo, les statistiques et les récoltes.

## Fonctionnalités
- Connexion et inscription Firebase ou authentification locale.
- Gestion des zones agricoles.
- Météo via une API HTTP.
- Suivi des récoltes : ajout, modification, suppression et historique.
- Quantité totale et statistiques par culture.
- Sauvegarde durable des récoltes avec `shared_preferences`.
- Navigation par onglets et gestion d’état avec Provider.

## Prérequis
- Flutter SDK compatible avec Dart 3.
- Android Studio / SDK Android ou un autre périphérique configuré pour Flutter.
- Pour Firebase : projet configuré avec les fichiers de plateforme appropriés.

## Installation
```bash
flutter pub get
flutter run
```

## Authentification
Le mode d’authentification est défini dans `lib/config.dart` :
- `utiliserFirebase = true` utilise Firebase Authentication.
- `utiliserFirebase = false` utilise l’authentification locale de démonstration.

## Structure
- `lib/models` : modèles métier.
- `lib/providers` : état partagé.
- `lib/screens` : écrans de l’application.
- `lib/services` : authentification et météo.
- `lib/theme` : thèmes clair et sombre.

## Vérification
```bash
flutter analyze
flutter test
flutter build apk
```
