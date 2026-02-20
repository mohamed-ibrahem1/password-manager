# Testing Guide

## Running Tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/models/password_entry_test.dart
flutter test test/services/password_generator_test.dart

# With coverage
flutter test --coverage
```

## Test Structure

```
test/
├── widget_test.dart                       # App widget smoke test
├── models/
│   └── password_entry_test.dart           # PasswordEntry model tests (14 tests)
└── services/
    └── password_generator_test.dart       # Password generator tests (19 tests)
```

## Manual Testing Checklist

### Authentication
- [ ] Google Sign-In works on Android
- [ ] Google Sign-In works on Windows
- [ ] Sign-out clears session
- [ ] Biometric prompt appears after sign-in
- [ ] PIN creation and verification works
- [ ] Lock screen appears on app resume

### Passwords
- [ ] Create password with all fields
- [ ] Edit existing password
- [ ] Delete password with confirmation
- [ ] Search/filter by category
- [ ] Password generator produces valid output
- [ ] Copy password to clipboard

### Images
- [ ] Upload image to category
- [ ] View images in grid
- [ ] Delete image

### Cross-Platform
- [ ] Android: full flow works
- [ ] Windows: desktop window + full flow works
- [ ] Dark mode renders correctly
