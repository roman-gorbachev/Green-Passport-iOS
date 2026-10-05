# Green Passport for iOS

A SwiftUI app that turns everyday eco-friendly actions into points and real rewards. It is the iOS port of the [Android app](https://github.com/roman-gorbachev/Green-Passport-Android) and shares its Firebase backend, so accounts, points, coupons and content are the same on both platforms. Content, moderation, QR codes and partner coupons are managed in the [web admin panel](https://github.com/roman-gorbachev/greenpassport-admin).

## Features

- **Tasks.** Self-reported, photo or QR-confirmed eco tasks with filters by status, confirmation, city and category, and favorites.
- **Rewards shop.** Points are exchanged for partner coupons; each coupon has a QR link for the partner's cashier, a live status and an expiry reminder.
- **Events.** A calendar of local events with sign-up, a reminder an hour before and QR check-in on site.
- **Map.** Recycling points and eco shops on Apple Maps, with search, filters, saved points and directions.
- **Community.** A forum and groups with chat; every text passes the same word filter as on Android.
- **Eco tips.** Articles, videos and kids' materials with bookmarks and points for reading.
- **Games.** Ten HTML5 mini-games from the shared catalog, opened full screen.
- **Profile.** Achievements, points history, a streak with a daily reminder, notifications, theme and language.
- **Moderation** for staff: the task photo queue and reported posts.

## Tech stack

- Swift, SwiftUI, Observation, Swift Concurrency
- Firebase Auth, Cloud Firestore, Cloud Functions, Storage (SwiftPM)
- Google Sign-In and Sign in with Apple
- MapKit, Core Location, VisionKit (`DataScannerViewController`)
- SwiftData for local game progress and the notification log

## Architecture

- `Green Passport/data/` — Firebase and local implementations. Repositories map Firestore documents by hand with the same field names as Android and expose offline-first `AsyncThrowingStream`s; points change only through callable functions.
- `Green Passport/domain/` — models, repository protocols and one use case per file.
- `Green Passport/presentation/` — the design system, navigation and one folder per feature with `ui/`, `viewmodels/` and `states/`. Each screen is a `Route` that owns an `@Observable` view model and a pure `Screen`.
- `Green Passport/di/AppDIContainer.swift` — the single composition root, without a DI framework.

The UX is shared with Android through [`claude/ux-spec.ru.md`](claude/ux-spec.ru.md); a difference that is not recorded there is a bug.

## Building

You need Xcode 26 and the iOS 26.5 SDK; the app runs on iOS 18 and later. Dependencies are resolved by Swift Package Manager when the project opens.

```bash
xcodebuild -project "Green Passport.xcodeproj" -scheme "Green Passport" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Simulator' build
```

Configuration:

- `Green Passport/GoogleService-Info.plist` is the Firebase client config of project `chatroom-85fb8`. Without it the app shows a setup screen instead of crashing.
- Set the `GOOGLE_REVERSED_CLIENT_ID` build setting to the plist's `REVERSED_CLIENT_ID` to enable Google sign-in.
- `GAMES_BASE_URL` and `COUPON_SCAN_URL` build settings point to the web games and the coupon link.
- Enable the Apple provider in Firebase Authentication for Sign in with Apple.

The QR scanner and the camera need a real device; on the Simulator the app says so instead of opening them.

## License

Proprietary. Copyright (c) 2026 Roman Gorbachev. All rights reserved. See [LICENSE](LICENSE).

## Author

Roman Gorbachev
