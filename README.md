# 🔐 Secure Password Manager

A modern, enterprise-grade password manager built with Flutter, featuring **two-layer authentication** (Google Sign-In + Biometric/PIN), cloud sync, and multi-user support.

## ✨ Features

### 🔒 Two-Layer Security
- **Google Sign-In** - Cloud authentication with multi-user support
- **Biometric Authentication** - Fingerprint, Face ID, Windows Hello
- **PIN Protection** - 4-6 digit PIN with secure local storage
- **User-specific Vaults** - Each user has isolated password storage

### ☁️ Cloud Features
- **Real-time Sync** - Access passwords across all devices
- **Firebase Firestore** - Secure, scalable cloud storage
- **Offline Access** - PIN unlock works without internet
- **Automatic Backup** - Never lose your passwords

### 💎 Modern UI
- **Material 3 Design** - Beautiful, modern interface
- **Dark Mode** - Easy on the eyes
- **Desktop & Mobile** - Optimized for all screen sizes
- **Smooth Animations** - Polished user experience

### 🛠️ Management
- **Password Generator** - Create strong, random passwords
- **Categories** - Organize passwords by type
- **Search** - Find passwords quickly
- **Custom Fields** - Store any credential type
- **Security Settings** - Manage authentication preferences

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/mohamed-ibrahem1/password-manager.git
cd passwords
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Google Sign-In Setup (Required)

**Quick Setup** (2-5 minutes):
- **Android**: See [QUICK_SETUP.md](QUICK_SETUP.md) - Just add SHA-1 to Firebase
- **Windows**: See [QUICK_SETUP.md](QUICK_SETUP.md) - Create OAuth credentials

**Full Guide**: [SETUP_GUIDE.md](SETUP_GUIDE.md) - Complete step-by-step instructions

### 4. Run the App

**Android:**
```bash
flutter clean
flutter pub get
flutter run -d android
```

**Windows:**
```powershell
# Configure OAuth first (see QUICK_SETUP.md)
flutter clean
flutter pub get
./run-windows.ps1
```

## 📖 Documentation

| Document | Description |
|----------|-------------|
| **[QUICK_SETUP.md](QUICK_SETUP.md)** | ⚡ 2-5 minute setup guide |
| **[SETUP_GUIDE.md](SETUP_GUIDE.md)** | 📚 Complete setup instructions |
| **[BIOMETRIC_PIN_GUIDE.md](BIOMETRIC_PIN_GUIDE.md)** | Biometric & PIN guide |
| **[AUTH_QUICK_REFERENCE.md](AUTH_QUICK_REFERENCE.md)** | Authentication tips |
| **[SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md)** | Technical architecture |
| **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** | Complete feature list |

## 🎯 How It Works

### Authentication Flow
```
1. Open App
   ↓
2. Sign in with Google (identifies your account)
   ↓
3. Biometric or PIN unlock (protects device access)
   ↓
4. Access your password vault ✅
```

### Data Storage
- **Cloud (Firestore)**: Passwords synced across devices
- **Local (Device)**: PIN stored securely on device
- **Isolation**: Each user has a separate, secure vault

## 💰 Cost

**100% FREE** using Firebase's generous free tier:
- ✅ Unlimited users
- ✅ 1 GB storage (~100,000 passwords)
- ✅ 50,000 reads/day
- ✅ 20,000 writes/day
- ✅ No credit card required

Perfect for personal use or small teams!

## 📱 Platform Support

| Platform | Google Sign-In | Biometric | PIN | Status |
|----------|----------------|-----------|-----|--------|
| Android | ✅ | ✅ Fingerprint | ✅ | Full Support |
| iOS | ✅ | ✅ Face ID/Touch ID | ✅ | Full Support |
| Windows | ✅ | ✅ Windows Hello | ✅ | Full Support |
| macOS | ✅ | ✅ Touch ID | ✅ | Full Support |
| Linux | ✅ | ❌ | ✅ | PIN Only |
| Web | ✅ | ❌ | ✅ | PIN Only |

## 🔐 Security

### Multi-Layer Protection
1. **Google OAuth** - Industry-standard authentication
2. **Biometric/PIN** - Device-level security
3. **Firestore Rules** - Server-side access control
4. **Encrypted Storage** - OS-level encryption
5. **User Isolation** - Separate vaults per user

### Attack Protection
- ❌ Can't access with just Google password (needs device)
- ❌ Can't access with just device (needs Google account)
- ❌ Can't access other users' data (server-side rules)
- ❌ Can't brute force (OS rate limiting)

**Security Rating: 🔒🔒🔒🔒🔒 (5/5)**

## 🛠️ Tech Stack

- **Flutter** - Cross-platform UI framework
- **Firebase Auth** - Authentication backend
- **google_sign_in_all_platforms** - Unified Google Sign-In (Android native + Windows OAuth)
- **Cloud Firestore** - NoSQL cloud database
- **Local Auth** - Biometric authentication
- **Shared Preferences** - Secure local storage
- **Material 3** - Modern design system

## 📸 Screenshots

### Login Screen
Beautiful Material 3 login with Google Sign-In

### Lock Screen
Biometric authentication with PIN fallback

### Password Vault
Organized categories with quick search

### Security Settings
Manage authentication preferences

## 🎮 Usage

### First Time
1. Open app → **Sign in with Google**
2. Create a 4-6 digit **PIN**
3. Start adding passwords!

### Daily Use
1. Open app → **Fingerprint/Face scan** (or enter PIN)
2. Access passwords instantly ✅

### Settings
- Profile menu → **Security Settings**
- Toggle biometric/PIN
- Change or delete PIN
- Sign out

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Author

**Mohamed Ibrahim**
- GitHub: [@mohamed-ibrahem1](https://github.com/mohamed-ibrahem1)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for free cloud services
- Material Design team for beautiful components

## 📞 Support

For questions or issues:
1. Check the [Documentation](GOOGLE_SIGNIN_SETUP.md)
2. Open an [Issue](https://github.com/mohamed-ibrahem1/password-manager/issues)
3. Read the [Quick Reference](AUTH_QUICK_REFERENCE.md)

---

**Made with ❤️ using Flutter**

**Stay Secure! 🔐**
