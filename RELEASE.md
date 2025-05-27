# Release Script

This repository includes a `create-release.sh` script that automates the release process.

## Quick Start

1. Make the script executable:
   ```bash
   chmod +x create-release.sh
   ```

2. Create a new release:
   ```bash
   ./create-release.sh 0.9.4
   ```

## What the script does:

1. **Validates the version format** (semantic versioning: x.y.z)
2. **Checks git repository status** (must be clean, no uncommitted changes)
3. **Updates the CLAUDE_VERSION** in `scripts/build-functions.sh`
4. **Commits the version change**
5. **Creates a git tag** with release notes
6. **Pushes the changes and tag** to origin
7. **Triggers GitHub Actions** to build and create the release

## Usage Examples

```bash
# Create version 0.9.4
./create-release.sh 0.9.4

# Create version 1.0.0
./create-release.sh 1.0.0
```

## Requirements

- Clean git working directory (no uncommitted changes)
- Push access to the repository
- Semantic versioning format (major.minor.patch)

## What happens after running the script

1. GitHub Actions will automatically build the AppImage
2. A new release will be created on GitHub
3. The AppImage will be attached to the release
4. Users can download the AppImage from the releases page

## Manual Release Alternative

If you prefer to create releases manually:

1. Update the version in `scripts/build-functions.sh`:
   ```bash
   CLAUDE_VERSION="0.9.4"
   ```

2. Commit and push the change:
   ```bash
   git add scripts/build-functions.sh
   git commit -m "Release v0.9.4: Update Claude version to 0.9.4"
   git push origin main
   ```

3. Create and push a tag:
   ```bash
   git tag -a v0.9.4 -m "Release v0.9.4"
   git push origin v0.9.4
   ```

The GitHub Action will automatically create a release and build the AppImage when it detects the new tag.
