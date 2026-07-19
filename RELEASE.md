# Release Process for SkillProof Mobile

## Coordinated Release Strategy

This repository contains both the Flutter mobile app and backend services (deployed on Render). Releases are coordinated using **git tags**.

## How to Release

### 1. Ensure Backend is Ready
- Verify all backend changes are deployed to Render
- Test the backend API at `https://api.skillproof.flairfuture.com`

### 2. Tag the Release
```powershell
# Create a version tag (e.g., v1.2.3)
git tag -a v1.2.3 -m "Release v1.2.3 - Feature X, Bug fix Y"

# Push the tag to GitHub
git push origin v1.2.3
```

### 3. GitHub Actions Builds Automatically
- The `build-apk.yml` workflow triggers on version tags
- Builds a production APK with Render endpoints configured
- Creates a GitHub Release with the APK attached

### 4. Download and Distribute
- Go to https://github.com/mukaabone-arch/skillproof-mobile/releases
- Download the APK from the latest release
- Distribute to testers or users

## Versioning Strategy

Use **semantic versioning** (MAJOR.MINOR.PATCH):
- `v1.0.0` - First production release
- `v1.1.0` - New features
- `v1.0.1` - Bug fixes

Example tags:
- `v1.2.3` - Production release
- `v1.2.3-rc1` - Release candidate (prerelease)
- `v1.2.3-beta` - Beta (prerelease)

## Syncing App and Backend Changes

1. **Backend deploys first**: Push backend changes to `main` → auto-deploy to Render
2. **App follows**: After backend is live, tag the app release
3. **Or together**: For coordinated features, merge both, then tag

## Local Testing Before Release

```powershell
# Test against production Render backend
.\run-prod.ps1

# Build APK locally
.\build-prod-apk.ps1
```

## Troubleshooting

- **APK build fails in CI**: Check Flutter/Java versions in workflow
- **API endpoints wrong**: Verify `--dart-define` flags in workflow match `prod.json`
- **Release not created**: Ensure `GITHUB_TOKEN` has repo permissions
