# Setup Guide

## Prerequisites

- Flutter SDK >= 3.6.1
- A [Supabase](https://supabase.com) account (free tier works)
- A Google Cloud project with OAuth 2.0 credentials

## 1. Supabase Project

1. Create a new project at [supabase.com](https://supabase.com)
2. Go to **Project Settings → API** and copy your **Project URL** and **anon public key**
3. Update `lib/config/supabase_config.dart` with your credentials:
   ```dart
   static const String url = 'https://YOUR-PROJECT.supabase.co';
   static const String anonKey = 'YOUR_ANON_KEY';
   ```

## 2. Database Schema

Run these SQL queries in **Supabase Dashboard → SQL Editor**:

### Passwords Table

```sql
CREATE TABLE passwords (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  fields JSONB NOT NULL,
  category TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE passwords ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own passwords" ON passwords FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own passwords" ON passwords FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own passwords" ON passwords FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own passwords" ON passwords FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_passwords_user_id ON passwords(user_id);
CREATE INDEX idx_passwords_category ON passwords(category);
CREATE INDEX idx_passwords_updated_at ON passwords(updated_at DESC);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_passwords_updated_at BEFORE UPDATE ON passwords
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### Saved Images Table

```sql
CREATE TABLE saved_images (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  image_data TEXT NOT NULL,
  category TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE saved_images ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own images" ON saved_images FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own images" ON saved_images FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own images" ON saved_images FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own images" ON saved_images FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_saved_images_user_id ON saved_images(user_id);
CREATE INDEX idx_saved_images_category ON saved_images(category);
CREATE INDEX idx_saved_images_updated_at ON saved_images(updated_at DESC);

CREATE TRIGGER update_saved_images_updated_at BEFORE UPDATE ON saved_images
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

## 3. Google OAuth

1. In **Supabase Dashboard → Authentication → Providers → Google**, enable Google sign-in
2. Enter your Google OAuth **Client ID** and **Client Secret**
3. In [Google Cloud Console → Credentials](https://console.cloud.google.com/apis/credentials), add this authorized redirect URI:
   ```
   https://YOUR-PROJECT-REF.supabase.co/auth/v1/callback
   ```

## 4. Run the App

```bash
flutter pub get
flutter run              # Android/iOS
flutter run -d windows   # Windows desktop
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Invalid API key | Verify URL and anon key in `supabase_config.dart` |
| Google Sign-In failed | Check OAuth is enabled in Supabase + redirect URIs match |
| Permission denied | Ensure RLS policies are created and user is authenticated |
