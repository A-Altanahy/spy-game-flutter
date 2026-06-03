# Spyfall Flutter

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Localization](https://img.shields.io/badge/Localization-Arabic%20%7C%20English-success)](#features)
[![Content](https://img.shields.io/badge/Content-GitHub%20Sync-informational)](#content-sync)

A cross-platform Spyfall party game built with Flutter. The app supports Arabic and English, local multiplayer sessions, offline content caching, and dynamic content sync from a companion GitHub content repository.

## Features

- Arabic and English localization with runtime locale support.
- Local multiplayer Spyfall flow for assigning a shared location to players while one player becomes the spy.
- GitHub-hosted content sync for categories, translations, and images.
- Offline cache using local app storage so downloaded content remains available after sync.
- Built-in image/category management foundations for maintaining game content.
- Mobile, desktop, and web Flutter project structure.
- No API keys required for the public content workflow.

## Tech Stack

- Flutter and Dart.
- `shared_preferences` for local preferences and cached metadata.
- `path_provider` for device-specific storage directories.
- `dio` for downloading remote content.
- `intl` and Flutter localization delegates.
- `google_fonts` for UI typography.

## Architecture

```text
lib/
├── main.dart                         # App bootstrap, locale notifier, and asset initialization
├── core/
│   ├── constants/                    # App-wide constants
│   ├── localization/                 # Localized string loading
│   └── theme/                        # Theme definitions
├── data/
│   ├── legacy/                       # Existing local photo data support
│   ├── models/                       # Category, image, and game settings models
│   └── services/                     # GitHub sync and local storage services
├── features/home/                    # Main game entry screen
└── shared/widgets/                   # Reusable buttons, cards, and loading components
```

## Content Sync

The app syncs content from:

- [A-Altanahy/spyfall-content](https://github.com/A-Altanahy/spyfall-content)

The content repository provides:

- `data.json` manifest of available categories and image files.
- `i18n/en.json` and `i18n/ar.json` translations.
- Public image assets organized by category.

Downloaded files are cached in the app documents directory. The game can continue using cached content when the device is offline.

## Running Locally

### Prerequisites

- Flutter SDK 3.3 or later.
- Android Studio, Xcode, or desktop build tools depending on the target platform.

### Setup

```bash
git clone https://github.com/A-Altanahy/spy-game-flutter.git
cd spy-game-flutter
flutter pub get
flutter run
```

Run on a specific target:

```bash
flutter run -d chrome
flutter run -d windows
flutter run -d android
```

## Testing

```bash
flutter test
```

## Portfolio Focus

This project highlights Flutter app architecture, localization, public-content delivery, offline-first storage, and a practical separation between app code and remotely maintained game assets.
