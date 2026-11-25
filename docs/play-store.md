# Google Play closed test

A checklist for getting the pilot to 50 to 200 testers through a closed test.

## 1. One-time setup

1. Create a Google Play developer account (one-time $25 fee) at
   https://play.google.com/console.
2. Finish Firebase setup from the README so the AI friend, the Tea Table and
   the story maker work for testers.
3. Create an upload key on your computer (keep the file and passwords safe,
   and never commit them):

   ```
   keytool -genkey -v -keystore ~/cozymoon-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

4. Create `android/key.properties` (git-ignored):

   ```
   storePassword=<your store password>
   keyPassword=<your key password>
   keyAlias=upload
   storeFile=/absolute/path/to/cozymoon-upload.jks
   ```

## 2. Build

```
flutter build appbundle --release
```

The file to upload is `build/app/outputs/bundle/release/app-release.aab`.
Raise `version:` in `pubspec.yaml` (for example `0.4.1+5`) before each new
upload.

## 3. In Play Console

1. Create app: name **CozyMoon**, app, free.
2. Testing → Closed testing → create a track, add testers by email list or a
   Google Group, upload the `.aab`.
3. Fill in the store listing (text below), upload `docs/store/icon-512.png`,
   a 1024×500 feature graphic and at least 2 phone screenshots.
4. App content:
   - **Privacy policy:** required. It must say what is stored on the phone
     (profile, check-ins, cycle dates, chat history) and what is sent to the
     server (chat messages, Tea Table posts and story requests, processed by
     Google Gemini).
   - **Data safety:** declare "Health info" and "Messages" collected only for
     app functionality, not shared for ads, data encrypted in transit, and that
     users can delete their data (Settings → Erase my data).
   - **Health apps declaration:** wellness / period tracking, not a medical
     device.
   - **Target audience:** 18+.
   - **Ads:** none.
   - **User-generated content:** the Tea Table is moderated before posting;
     mention the report flow when it ships.
5. Send for review. Closed tests are usually reviewed within a few days.
   New personal developer accounts must run a closed test with at least 12
   testers for 14 days before they can publish to production.

## Store listing draft

**Short description (80 chars max)**
A cozy friend for period days, stress and growing older on your own terms.

**Full description**
CozyMoon is a warm, playful companion for women, made especially for those
living life on their own terms.

• Confide in a friend who gets it. Vent, ask about your body, or share a small
  win. Turn on Burn After Venting and nothing is saved.
• The Tea Table: ask anything anonymously. Get a private answer just for you
  first, then decide whether to share it with kind women who've been there.
• Cozy Nook: brain-free games, five-minute stories, calm videos and soft rain,
  piano and fireplace sounds for hard days.
• Learn: three gentle steps a day about your cycle, sleep, cravings and
  keeping your bones and muscles strong as you level up through your 30s,
  40s and beyond.
• Private by design: your cycle dates and check-ins stay on your phone.

CozyMoon is a wellness companion, not a medical service.

## Release notes for this build

First pilot: onboarding, AI friend chat, the Tea Table, the Cozy Nook and
the Learning Hub. Thank you for testing! Tell us what felt cozy and what
didn't.
