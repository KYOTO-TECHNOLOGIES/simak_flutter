# Grill and Fry preview

`grill-fry-category.png` is a Flutter-rendered capture of the implemented ProductsPage
with the Grill and Fry category selected. It uses sample catalog data and existing
local food photographs for a repeatable offline preview. The app still loads its
products, prices and availability from the backend.

Recreate with:
`.tooling/flutter/bin/flutter test --no-pub --dart-define=CHECK_GRILL_PREVIEW=true test/grill_fry_preview_test.dart --update-goldens`

Cart addon editing and independent addon prices require the matching changes in
`uae_backend_staging`, including Orders migration 0013, before releasing the app.
The backend migration must be applied during deployment before releasing the app.
