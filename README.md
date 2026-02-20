# Secure Password Manager

A Flutter password manager with two-layer authentication (Google Sign-In + Biometric/PIN), cloud sync via Supabase, and Material 3 UI.

## Features

- **Two-layer auth** — Google OAuth (cloud) + Biometric/PIN (local device)
- **Cloud sync** — Passwords stored in Supabase PostgreSQL with Row Level Security
- **Password generator** — Configurable strong password creation
- **Categories** — Organize passwords and saved images by type
- **Material 3** — Modern UI with dark mode support
- **Cross-platform** — Android, iOS, Windows desktop

## Quick Start

```bash
git clone https://github.com/mohamed-ibrahem1/password-manager.git
cd passwords
flutter pub get
```

1. Set up Supabase credentials — see [docs/SETUP.md](docs/SETUP.md)
2. Run the app:
   ```bash
   flutter run              # Android/iOS
   flutter run -d windows   # Windows
   ```

## Project Structure

```
lib/
├── main.dart              # Mobile entry point
├── main_windows.dart      # Windows entry point
├── app.dart               # Material 3 app shell
├── config/                # Supabase credentials
├── models/                # Data models (password, image)
├── pages/                 # UI screens
└── services/              # Auth, database, local auth
```

## Documentation

| Doc | Description |
|-----|-------------|
| [docs/SETUP.md](docs/SETUP.md) | Supabase setup, database schema, Google OAuth |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | System design, auth flow, security model |
| [docs/TESTING.md](docs/TESTING.md) | Running tests, manual testing checklist |

## Platform Support

| Platform | Google Sign-In | Biometric | PIN |
|----------|:-:|:-:|:-:|
| Android | ✅ | ✅ Fingerprint | ✅ |
| iOS | ✅ | ✅ Face ID / Touch ID | ✅ |
| Windows | ✅ | ✅ Windows Hello | ✅ |

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Flutter (Dart, SDK ^3.6.1) |
| Auth | Supabase Auth + Google OAuth |
| Database | Supabase PostgreSQL + RLS |
| Local Auth | `local_auth` + `shared_preferences` |
| UI | Material 3 |

## License

MIT

## Author

**Mohamed Ibrahim** — [@mohamed-ibrahem1](https://github.com/mohamed-ibrahem1)
