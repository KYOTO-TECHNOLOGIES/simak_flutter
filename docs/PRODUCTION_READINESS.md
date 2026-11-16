# Flutter production readiness review

This review applies to `staging/flutter-addons-localization-apk` in the Simak
Flutter repository. Release changes are prepared for PR promotion to staging, Android `main`, and
iOS `deployiosrizan-cicdios`. This document records pre-release validation;
production backend changes and restarts require a separate user instruction.

## Rollout order: Flutter first, backend on explicit instruction

The agreed rollout is to submit the Flutter production release first, allowing
time for Play Store processing. Update the production backend only after the user
explicitly instructs us to do so. Production builds must use the production API.
The app has been tested against the staging feature contract; the current
production backend does not yet provide the new add-on and localization features.
Read-only live catalog requests confirmed:

| Capability | Staging | Production |
| --- | --- | --- |
| Product `addons` response field | Present | Missing |
| Product `name_arabic` / `name_chinese` | Present | Missing |
| Preparation specifications and sample images | Present, sample URLs return 200 | Present, sample URLs return 200 |

Source comparison also found the production backend lacks the new `CartItemAddon`
model, cart add-on price calculation, and `update_item_addons` implementation.
Unauthenticated route requests return 401, so those requests alone cannot prove
whether an authenticated cart action is available.

When the user authorizes the backend rollout, promote the compatible backend
code and database migrations, configure the production add-on/translation catalog
data, and verify authenticated cart/order flows. Production needs its own add-on
images and records; staging catalog data is not transferred by an app build.
Until then, the production API continues to provide its existing feature set.
This review did not modify either backend or run migrations.

The Android and iOS store workflows do not require the backend upgrade to be
complete before submitting the app. The temporary backend compatibility gate was
removed to follow the user's rollout order. App deployment must not trigger a
production backend deployment, migration, or restart.

## Build API configuration

`Env.baseUrl` now reads the compile-time `API_BASE_URL` value. Local/default
builds remain on staging so this branch continues to be safe to test. An APK
already downloaded cannot switch APIs without being rebuilt.

- Staging APK workflow explicitly selects `https://stage.simakfresh.ae/api/`.
- Android production workflow explicitly selects `https://simakfresh.ae/api/`.
- iOS production workflow passes the same production setting through encoded
  Xcode `DART_DEFINES`.
- Relative media paths use the selected API's origin. Absolute media URLs remain
  as supplied by the backend.

The production Android build command is:

```sh
flutter build appbundle --release --dart-define=API_BASE_URL=https://simakfresh.ae/api/
```

The staging APK uses debug signing and the production application ID. It is a
test artifact, not the signed Play Store release artifact. Use the release-signed
AAB workflow for Play. The release app version is `1.0.10+19` (previously `1.0.9+18`); verify that the next
production version code is greater than the version already uploaded to Play.
The current published store version was not accessible for this review.

## Add-on and preparation images

- Product details already display both preparation and add-on images.
- The preparation selection modal already displays supplied preparation images.
- The cart add-on editing modal was missing thumbnails; this review adds them.
- Images are optional backend fields. An absent image does not create a thumbnail;
  a failed network image uses the existing shared logo fallback.
- The standalone preparation modal contains preparation choices; products with
  add-ons are directed to the product detail screen for add-on selection.

A sample of 50 staging products contained two distinct add-on image URLs; both
returned HTTP 200 with image content types. Eight sampled preparation image URLs
on each environment also returned HTTP 200. This was a sample, not an audit of
every uploaded image. Production currently exposes no add-on catalog field.

## Validation and remaining checks

- All 24 Flutter tests passed with cached dependencies and one test worker.
- Regression coverage includes API/media origin selection, preparation modal
  images, cart add-on modal images/quantities, localization, auth model merging,
  and the Grill & Fry page widget.
- Production API/media compile-time selection also passed its isolated test.
- Static analysis: no errors; five existing warnings and eleven informational
  style notices in unrelated files. Logs are under `.tooling/release-review-*`.
- All three workflow YAML files and their embedded Bash syntax validated.
- No dependency install, APK/AAB/IPA build, authenticated live order, payment,
  device login, push-notification test, store upload, or production change ran.

For the app submission, verify release signing, version codes, and platform-specific
behavior on devices. When the backend rollout is authorized, exercise login, adding
preparation/add-ons, changing cart item quantity without changing add-on quantity,
editing/removing add-ons, translated categories, order totals, and checkout against
the upgraded production backend.

## Existing store workflow and iOS authentication audit

Compared the local Android store workflow with `origin/main` and the local iOS
store workflow with `origin/deployiosrizan-cicdios`. Both remain semantically
identical to those branch versions except the explicit production API build
setting. Existing signing, certificate/profile handling, Firebase checks,
archive/export, store credentials, and upload steps were preserved.

| Workflow | Trigger branch | API target |
| --- | --- | --- |
| Play Store | `main` | Production |
| App Store Connect | `deployiosrizan-cicdios` | Production |
| Download staging APK | `staging/flutter-addons-localization-apk` | Staging |

Validated all workflow YAML and embedded Bash syntax. Evaluated the iOS encoded
`DART_DEFINES` value and confirmed it decodes to the production API setting.
The installed Flutter tool forwards that build setting into its Dart compilation.
A staging branch push alone does not trigger either store upload workflow.
These edits must be included when promoting app code into each release branch;
include the app version bump to `1.0.10+19` when promoting these changes.

Google sign-in was already commented out on the login form. The registration
form still showed it, including in the current remote iOS deployment branch.
Added an iOS platform guard around the registration Google button and its divider.
Three widget tests passed: hidden on iOS registration, hidden on iOS login, and
still visible on Android registration. This behavior is controlled in Flutter
widget code, independently of the API setting and the store workflow.

Store signing and upload jobs were not executed in this review. Previously
successful workflow structure was preserved, but this is not a guarantee that
current signing secrets, runner images, store version numbers, or store-side
validation will succeed. GitHub Actions outcomes must be checked after the release PRs are merged.
Production backend deployment remains deferred until explicit user instruction.
