# Architecture

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| Auth | Supabase Auth + Google OAuth |
| Database | Supabase (PostgreSQL) with Row Level Security |
| Local Security | `local_auth` (biometrics) + `shared_preferences` (PIN) |
| Desktop | `window_manager` + `bitsdojo_window` |

## Project Structure

```
lib/
├── main.dart                 # Default entry point (mobile)
├── main_windows.dart         # Windows entry point (desktop window config)
├── app.dart                  # Material 3 themed app shell (Windows)
├── config/
│   └── supabase_config.dart  # Supabase credentials
├── models/
│   ├── password_entry.dart   # Password data model
│   └── image_entry.dart      # Image data model
├── pages/
│   ├── home_page.dart              # Main navigation hub
│   ├── login_page.dart             # Google Sign-In screen
│   ├── biometric_lock_screen.dart  # PIN/biometric lock
│   ├── lock_screen_page.dart       # Lock screen UI
│   ├── security_settings_page.dart # Auth settings
│   ├── category_grid_page.dart     # Password categories grid
│   ├── password_list_page.dart     # Passwords in a category
│   ├── add_password_page.dart      # Create/edit password
│   ├── password_generator_page.dart# Secure password generator
│   ├── image_category_grid_page.dart# Image categories grid
│   └── image_list_page.dart        # Images in a category
└── services/
    ├── auth_service.dart             # Google OAuth via Supabase
    ├── supabase_database_service.dart# CRUD for passwords & images
    ├── firestore_service.dart        # Password CRUD (Supabase, legacy name)
    ├── image_storage_service.dart    # Image storage logic
    └── local_auth_service.dart       # Biometrics + PIN
```

## Two-Layer Authentication

```
User opens app
      │
      ▼
┌─────────────────────┐
│  Layer 1: Cloud Auth │  Google Sign-In via Supabase
│  (Account identity)  │  Syncs across devices, needs internet
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  Layer 2: Local Auth │  Biometric / PIN via local_auth
│  (Device protection) │  Device-specific, works offline
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  App (Home Page)     │  Full access to passwords & images
└─────────────────────┘
```

## Auth State Flow

| State | Screen | Trigger |
|-------|--------|---------|
| Loading | Spinner | App start |
| Not authenticated | `LoginPage` | No Supabase session |
| Cloud auth only | `BiometricLockScreen` | Signed in, local auth pending |
| Fully authenticated | `HomePage` | Both layers passed |

## Data Flow

- **Passwords & Images**: Stored in Supabase PostgreSQL with per-user Row Level Security
- **Local settings** (PIN hash, biometric toggle): `SharedPreferences` on device
- **Auth session**: Managed by `supabase_flutter` (persists across restarts)

## Security Model

| Attack Vector | Protection |
|---------------|------------|
| Stolen Google password | Blocked by device PIN/biometric |
| Stolen unlocked device | Blocked by Google account requirement |
| Stolen device + known PIN | Blocked by Google account requirement |
| Database breach | RLS ensures users only access own rows |
