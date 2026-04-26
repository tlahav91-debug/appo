# AppLoop — Deployment Guide

## Part 1: Test on Your Mac (iOS Simulator)

The simulator is the fastest way to verify UI and core flows before sending to TestFlight. Most features work; a few are simulator-only limitations (noted below).

### 1.1 One-time Mac setup

```bash
# Install Flutter (if not already installed)
# https://docs.flutter.dev/get-started/install/macos

# Verify everything is set up
flutter doctor

# Install Xcode from the Mac App Store, then accept the licence
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# Install iOS simulators via Xcode → Settings → Platforms → iOS
```

### 1.2 Clone and install dependencies

```bash
git clone https://github.com/tlahav91-debug/appo.git
cd appo
git checkout claude/setup-multi-agent-drama-game-6lPuh   # or main after merging
flutter pub get
cd ios && pod install && cd ..
```

### 1.3 Add required secret files

Before running, two files must be added manually (they are not in the repo):

**A. Firebase config**
Download `GoogleService-Info.plist` from Firebase Console:
- Firebase Console → your project → Project Settings → iOS app → Download `GoogleService-Info.plist`
- Place it at: `ios/Runner/GoogleService-Info.plist`

**B. AdMob App ID**
Open `ios/Runner/Info.plist` and set your AdMob App ID:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
```

### 1.4 Run on simulator

```bash
# List available simulators
flutter emulators

# Launch a specific simulator (e.g. iPhone 15 Pro)
flutter emulators --launch apple_ios_simulator

# Run the app with all required dart-defines
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... \
  --dart-define=RC_IOS_KEY=appl_XXXXXXXXXXXXXXXXXXXXXXXXXX \
  --dart-define=POSTHOG_API_KEY=phc_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

> **Tip:** Create a `run_simulator.sh` file locally (add it to `.gitignore`) with the dart-defines pre-filled so you don't type them every time.

### 1.5 What works on simulator vs what doesn't

| Feature | Simulator | Notes |
|---------|-----------|-------|
| All screens + navigation | ✅ | Full UI testing |
| Supabase auth (email/password) | ✅ | |
| Episode unlock + choice flow | ✅ | |
| Energy system | ✅ | |
| Coins, gems, leaderboard | ✅ | |
| Lava Quest, Race | ✅ | |
| Meta World, Inbox | ✅ | |
| Continue Watching, Discover | ✅ | |
| RevenueCat IAP purchases | ⚠️ | Use StoreKit test environment in Xcode; real purchases need a device |
| AdMob rewarded ads | ⚠️ | Test ads show; real fill requires device |
| Push notifications (FCM) | ❌ | Simulator cannot receive push; test on a real device |
| Camera / photo library | ❌ | Simulator has no camera |

### 1.6 Run with hot reload

While the app is running, press:
- `r` — hot reload (instant UI changes)
- `R` — hot restart (full app restart, resets state)
- `q` — quit

---

## Part 2: Build for TestFlight

### 2.1 Prerequisites

- [ ] Apple Developer account (paid, $99/yr) — [developer.apple.com](https://developer.apple.com)
- [ ] App registered in App Store Connect with Bundle ID (e.g. `com.yourcompany.apploop`)
- [ ] Distribution certificate + provisioning profile set up in Xcode
- [ ] All third-party services configured (see Section 2.2)

### 2.2 Configure third-party services

#### Supabase
1. Apply all migrations to your production project:
```bash
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```
2. Deploy all Edge Functions:
```bash
supabase functions deploy --all
```
3. Set Edge Function secrets in Supabase Dashboard → Settings → Edge Functions → Secrets:

| Secret | Value |
|--------|-------|
| `SUPABASE_SERVICE_ROLE_KEY` | From Supabase Dashboard → Settings → API |
| `FCM_PROJECT_ID` | From Firebase Console → Project Settings |
| `FCM_SERVICE_ACCOUNT_JSON` | Full JSON of your Firebase service account key |

#### Firebase
- Download `GoogleService-Info.plist` and place at `ios/Runner/GoogleService-Info.plist`
- Enable FCM in Firebase Console → Cloud Messaging
- Upload your APNs key: Firebase Console → Project Settings → Cloud Messaging → iOS app → APNs Auth Key

#### RevenueCat
- Create your app in [app.revenuecat.com](https://app.revenuecat.com)
- Set up products matching the gem pack SKUs in the code
- Copy your iOS public API key (starts with `appl_`)

#### AdMob
- Create an iOS app in [admob.google.com](https://admob.google.com)
- Copy the App ID into `ios/Runner/Info.plist` (key: `GADApplicationIdentifier`)
- Create a Rewarded ad unit and note the ad unit ID

#### PostHog
- Create a project at [posthog.com](https://posthog.com)
- Copy your API key (starts with `phc_`)

### 2.3 Update app version

In `pubspec.yaml`, bump the version before each TestFlight build:
```yaml
version: 1.0.1+2   # format: marketing_version+build_number
```
Build number must increase with every upload to TestFlight.

### 2.4 Merge the feature branch

```bash
git checkout main
git merge claude/setup-multi-agent-drama-game-6lPuh
git push origin main
```

### 2.5 Build the iOS archive

```bash
flutter build ipa \
  --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=RC_IOS_KEY=appl_... \
  --dart-define=POSTHOG_API_KEY=phc_
```

This produces the archive at: `build/ios/archive/Runner.xcarchive`
And the IPA at: `build/ios/ipa/drama_play.ipa`

### 2.6 Upload to TestFlight

**Option A — Transporter app (easiest)**
1. Download [Transporter](https://apps.apple.com/app/transporter/id1450874784) from the Mac App Store
2. Sign in with your Apple ID
3. Drag `build/ios/ipa/drama_play.ipa` into Transporter
4. Click Deliver

**Option B — Xcode**
1. Open Xcode → Window → Organizer
2. Select your archive → Distribute App → App Store Connect → Upload

**Option C — Command line**
```bash
xcrun altool --upload-app \
  --file build/ios/ipa/drama_play.ipa \
  --type ios \
  --apiKey YOUR_API_KEY_ID \
  --apiIssuer YOUR_ISSUER_ID
```

### 2.7 Invite TestFlight testers

1. Go to App Store Connect → your app → TestFlight
2. **Internal testers**: add by Apple ID — available within minutes
3. **External testers**: add by email — requires Apple review (usually 24–48 hrs for first build)
4. Testers install the [TestFlight app](https://apps.apple.com/app/testflight/id899247664) on their iPhone and accept your invite

---

## Part 3: Environment Variables Reference

| Variable | Used by | Where to get it |
|----------|---------|-----------------|
| `SUPABASE_URL` | App, all features | Supabase Dashboard → Settings → API |
| `SUPABASE_ANON_KEY` | App, all features | Supabase Dashboard → Settings → API |
| `RC_IOS_KEY` | RevenueCat IAP | RevenueCat Dashboard → your app → API Keys |
| `POSTHOG_API_KEY` | Analytics | PostHog → Project Settings → Project API Key |
| `GADApplicationIdentifier` | AdMob (in Info.plist) | AdMob Console → Apps → your app |

---

## Part 4: Quick Reference

### Simulator run (one command after setup)
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=RC_IOS_KEY=appl_... \
  --dart-define=POSTHOG_API_KEY=phc_...
```

### TestFlight build (one command after setup)
```bash
flutter build ipa --release \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=RC_IOS_KEY=appl_... \
  --dart-define=POSTHOG_API_KEY=phc_...
# Then drag build/ios/ipa/*.ipa into Transporter
```

### Deploy Supabase changes
```bash
supabase link --project-ref YOUR_REF
supabase db push                    # applies migrations
supabase functions deploy --all     # deploys Edge Functions
```
