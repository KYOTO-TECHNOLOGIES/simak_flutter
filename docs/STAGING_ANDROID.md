# Staging Android builds

Branch: `staging/flutter-addons-localization-apk`.

Push this branch to GitHub, then open **Actions → Download Staging Android APK**.
After a successful run, use the download link in the run summary or download
`simak-staging-apk-<run number>` under **Artifacts**. Extract the ZIP and install
`simak-staging.apk` on an Android device. Artifacts remain available for 14 days
and require access to this repository on GitHub.

The app uses `https://stage.simakfresh.ae/api/`. This workflow builds a release
APK signed with the runner's debug key via `STAGING_BUILD=true`; it needs no
Play Store signing secrets. Existing store publishing workflows are unchanged.
The staging APK uses the existing app package/Firebase configuration. Because
its signing certificate differs, uninstall an existing Play Store build before
installing it; uninstalling clears local app data. Runner debug keys can also
change between builds, requiring uninstall/reinstall. Google sign-in may need
the staging signing certificate registered in Firebase. Do not distribute this
APK as a production update.

## Content and add-ons

English API data, including the admin's Arabic and Chinese fields, is cached.
The app resolves those fields when displaying products, preparation options,
add-ons and banners. Changing language updates cached data without fetching it
again. Empty translations fall back to English. Category names remain English
internally because the backend filters `category_name` by its English name;
category display uses the admin's translated name.

Add-ons submit as `addons: [{id, quantity}]`, matching the staging backend.
Products with add-ons open the detail screen for selection from quick-add and
Buy Now. Selected add-ons remain attached when a preparation option is chosen.
The cart displays the server's selected add-ons, quantities and charges.
The `/grill_fry` route uses the real catalog instead of demo products.

## Validation

Run `flutter pub get --enforce-lockfile`, `flutter test` and
`STAGING_BUILD=true flutter build apk --release` with Flutter 3.38.10 and Java 17.
The workflow checks Dart errors and runs the tests before creating the APK.
Existing unrelated analyzer warnings are reported without blocking the build.

On a staging device, verify a Grill & Fry product with two different add-on
selections creates distinct cart lines; changing/removing one line preserves
the other. Check preparation plus add-ons, quantity limits, server totals,
and checkout. Enter distinct EN/AR/CN product/category/add-on/banner text in
staging admin, switch languages, then test missing translations and offline
language changes. Payment, push notifications and sign-in require device testing.

Local checks completed: all 14 tests passed; `flutter build bundle --debug --no-pub`
compiled the complete Dart app. Static analysis found no errors; existing
warnings and style notices remain in unrelated files. An Android APK has not
been built locally because this workspace has no Android SDK or Java runtime.
