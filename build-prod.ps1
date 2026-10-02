param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('apk', 'aab')]
    [string]$Target
)

$ErrorActionPreference = "Stop"

# Production build for MyAmbii candidate app.
#
# Backend is NestJS on AWS ECS Fargate (ap-south-1) behind an ALB at
# api.myambii.com. It is NOT on Render and there is NO automatic deploy,
# whatever RELEASE.md says — that document has sent people to verify a
# system that does not exist, twice.
#
# Every --dart-define below is load-bearing. GOOGLE_SERVER_CLIENT_ID in
# particular has no defaultValue in GoogleAuthConfig, so a build missing it
# ships serverClientId: null. Google then signs the user in, returns no
# server auth code, the backend exchange never happens, and the app drops
# back to the login screen with no error at all. Nothing warns you at build
# time. This cost a day on 2026-09-30.
#
# One script for both targets so the defines cannot drift between them.

$defines = @(
    "--dart-define=API_BASE_URL=https://api.myambii.com"
    "--dart-define=WEB_BASE_URL=https://www.myambii.com"

    # Ignored on Android: google_sign_in resolves the OAuth client by package
    # name + signing certificate SHA-1, not by this value — and this is the
    # DEBUG client anyway. Kept for iOS and parity. Do not "correct" it
    # expecting Android behaviour to change.
    "--dart-define=GOOGLE_ANDROID_CLIENT_ID=637578179718-vf95oh1otj1s62ji1hes1lpeqg0564q6.apps.googleusercontent.com"

    # The WEB client. This is the one that must be right.
    "--dart-define=GOOGLE_SERVER_CLIENT_ID=637578179718-4du7jp8kee08gltqbkouae1bbts1keck.apps.googleusercontent.com"
)

if ($Target -eq 'aab') {
    $command = 'appbundle'
    $output  = 'build/app/outputs/bundle/release/app-release.aab'
    $note    = 'Upload this to Play Console.'
} else {
    $command = 'apk'
    $output  = 'build/app/outputs/flutter-apk/app-release.apk'
    $note    = 'Sideload only. Signed with the upload key, not the Play app signing key.'
}

# Delete any previous artifact first. A stale file is a silent failure —
# you upload yesterday's build and spend an afternoon debugging code that
# was never in it. A missing file is a loud one.
if (Test-Path $output) {
    Write-Host "Removing previous artifact: $output"
    Remove-Item $output -Force
}

Write-Host "Building $Target ..."
Write-Host ""

flutter build $command $defines --release

if ($LASTEXITCODE -ne 0) {
    throw "flutter build $command failed with exit code $LASTEXITCODE"
}

if (-not (Test-Path $output)) {
    throw "flutter build reported success but $output does not exist."
}

$item = Get-Item $output
$version = (Select-String -Path pubspec.yaml -Pattern '^version:').Line

Write-Host ""
Write-Host "Built   : $($item.FullName)"
Write-Host "Size    : $([math]::Round($item.Length / 1MB, 1)) MB"
Write-Host "Modified: $($item.LastWriteTime)"
Write-Host "pubspec : $version"
Write-Host ""
Write-Host $note
Write-Host ""
Write-Host "Reminder: the number after '+' in pubspec version is the versionCode."
Write-Host "It must be higher than every build ever uploaded, on any track, forever."
