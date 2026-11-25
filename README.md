# CozyMoon

A cozy, playful period, stress-relief and pro-aging companion for women. It
feels like a close friend: you can confide anything, play brain-free games,
and learn about your body a few tiny steps at a time.

Built with **Flutter** (Android first, iPhone later) and **Firebase**.

## Pilot progress

| Week | What | Status |
| --- | --- | --- |
| 1 | Onboarding, Home, AI friend chat | ✅ done |
| 2 | The Tea Table (anonymous Q&A with a private first answer) | ✅ done |
| 3 | Cozy Nook (games, stories, calm videos, soft sounds) | next |
| 4 | Learning Hub (3 gentle steps a day), closed test on Google Play | planned |

## What works now

- **Onboarding:** three skippable questions (nickname or nameless, friend vibe,
  how you feel, last period date). "Skip, let's just chat" goes straight home.
- **Home:** greeting from the companion, cycle day with *Cozy Cocoon Mode* or
  *Main Character Energy*, quick mood chips, chat starters, day and night themes.
- **Friend chat:** replies match the chosen vibe and cycle phase. *Burn After
  Venting* keeps a chat in memory only and wipes it when turned off or when you
  leave. A safety check shows a calm help banner with helplines for crisis words,
  even offline. If the AI is not reachable, the friend answers warmly instead of
  showing an error. There is a daily cap of 20 AI replies per user.
- **The Tea Table:** anonymous board with topic filters and 8 warm starter
  posts. Every post and reply gets a new random alias (no profiles, no DMs).
  When she writes, she first gets a private *Just for you* answer from the
  friend plus 1 to 2 helpful replies from similar posts, then chooses
  *Keep it private* or *Share anonymously*. Posts and replies are checked for
  personal details (emails, phones, handles, links) and unkindness, and crisis
  posts are kept private with the help banner instead of being published.
  Send Hug works once per post or reply. Without Firebase the table runs on
  the phone only; with Firebase everyone shares one table through the
  `teaFeed`, `teaFirstAnswer`, `teaPublish`, `teaReply` and `teaHug` functions,
  which also run an AI kindness check and never store who wrote what.
- **Privacy:** profile, check-ins, cycle dates and saved chat stay on the phone.

## Run it

1. Install Flutter (3.27 or newer) and Android Studio.
2. `flutter pub get`
3. `flutter run` with an Android phone or emulator connected.

The app runs without Firebase: the friend then uses offline replies.

## Turn on the real AI friend (Firebase + Gemini)

1. Create a Firebase project at https://console.firebase.google.com and add an
   Android app with package name `app.cozymoon.cozymoon`.
2. Download `google-services.json` into `android/app/` (it is git-ignored), and
   add the Google services Gradle plugin as the Firebase console shows.
3. Upgrade the project to the Blaze plan (Cloud Functions need it; the free
   allowance covers a small pilot).
4. Get a Gemini API key from https://aistudio.google.com/apikey and store it:
   `firebase functions:secrets:set GEMINI_API_KEY`
5. Turn on Firestore in the Firebase console (production mode).
6. Deploy the functions and the locked-down Firestore rules:
   `cd functions && npm install && cd .. && firebase deploy --only functions,firestore:rules`

## Tests

- App: `flutter test`
- Cloud Function helpers: `cd functions && npm test`

## Not medical advice

CozyMoon is a wellness companion. It does not diagnose or treat anything.
