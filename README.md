# Spyfall Game App

An Arabic-friendly Flutter Spyfall party game with Google Drive-backed image categories, offline caching, and local multiplayer gameplay.

## Features

- Arabic and English localization
- Google Drive sync for custom category images
- Offline cache for downloaded content
- Built-in photo and category management
- Flutter targets for desktop, mobile, and web

## Local Setup

The app expects a Google Drive API key and a Drive folder ID at build time.

1. Create a Google Drive folder for your game content.
2. Share it as viewable to anyone with the link.
3. Create a Google Cloud API key with Drive API access.
4. Run the app with `--dart-define` values:

```bash
flutter run \
  --dart-define=DRIVE_API_KEY=your_google_drive_api_key \
  --dart-define=DRIVE_FOLDER_ID=your_google_drive_folder_id
```

You can also copy one of the example scripts and fill in your own values:

- `run_dev.sh.example`
- `run_dev.bat.example`

The compile-time configuration lives in `lib/core/config/env_config.dart`.

## Expected Drive Structure

```text
Main Folder
├── spy.png
├── Category1/
│   ├── image1.png
│   └── image2.jpg
├── Category2/
│   ├── image1.png
│   └── image2.jpg
└── ...
```

## Troubleshooting

- Confirm the folder is shared correctly.
- Confirm the API key is restricted to Google Drive API usage.
- Make sure both `DRIVE_API_KEY` and `DRIVE_FOLDER_ID` are passed in at runtime.
