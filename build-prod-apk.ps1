$ErrorActionPreference = "Stop"

# Build production APK with Render backend configuration
flutter build apk `
  --dart-define=API_BASE_URL=https://api.skillproof.flairfuture.com `
  --dart-define=WEB_BASE_URL=https://skillproof.flairfuture.com `
  --dart-define=GOOGLE_ANDROID_CLIENT_ID=637578179718-vf95oh1otj1s62ji1hes1lpeqg0564q6.apps.googleusercontent.com `
  --dart-define=GOOGLE_SERVER_CLIENT_ID=637578179718-4du7jp8kee08gltqbkouae1bbts1keck.apps.googleusercontent.com `
  --release

Write-Host "APK built successfully at: build/app/outputs/flutter-apk/app-release.apk"
