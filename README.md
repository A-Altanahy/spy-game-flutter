# Spyfall Game App

An Arabic-friendly Flutter Spyfall party game with offline caching, local multiplayer gameplay, and content sync from the public `spyfall-content` repository.

## Features

- Arabic and English localization
- Content sync from GitHub-hosted category data and images
- Offline cache for downloaded content
- Built-in photo and category management
- Flutter targets for desktop, mobile, and web

## Local Setup

```bash
flutter pub get
flutter run
```

No API keys or `--dart-define` values are required.

## Content Sync

The app downloads its content manifest, translations, and images from:

- `A-Altanahy/spyfall-content`

Synced files are cached locally under the app documents directory.

## Troubleshooting

- Make sure the device has internet access before running a sync.
- If synced names do not update immediately, run the cloud sync action again from the photo editor.
