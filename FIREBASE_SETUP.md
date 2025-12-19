Firebase setup (quick guide)
=============================

This project includes Firebase code (Authentication + Firestore). To enable Firebase on each platform, follow these steps.

Android
-------
1. In the Firebase Console, create a project and add an Android app with your package name (check `android/app/src/main/AndroidManifest.xml` for the package name).
2. Download the `google-services.json` file and place it at `android/app/google-services.json`.
3. Edit `android/build.gradle` and add the Google services classpath if not present:

   buildscript {
     dependencies {
       classpath 'com.google.gms:google-services:4.3.15'
     }
   }

4. Edit `android/app/build.gradle` and add at the bottom:

   apply plugin: 'com.google.gms.google-services'

5. (Optional but recommended) Run the FlutterFire CLI to generate `lib/firebase_options.dart`:

   ```bash
   flutterfire configure
   ```

iOS
---
1. In the Firebase Console, add an iOS app with your bundle identifier.
2. Download `GoogleService-Info.plist` and place it in `ios/Runner/` (add it to Xcode project).
3. (Optional) Run `flutterfire configure` to generate `lib/firebase_options.dart`.

Web
---
1. Add a Web app in Firebase Console and copy the config.
2. `flutterfire configure` will generate the `firebase_options.dart` file that includes web options.

Notes
-----
- The app currently calls `Firebase.initializeApp()` at startup; if platform config files are missing the app will continue to run locally but Firebase services won't be available until configured.
- After adding platform files, run:

```bash
flutter clean
flutter pub get
flutter run
```

If you prefer, I can add `lib/firebase_options.dart` (requires the Firebase project configuration), or I can guide you through the `flutterfire` CLI steps.
