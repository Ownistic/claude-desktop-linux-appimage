#!/bin/bash

# Script to create a new release with flexible versioning
# Usage: ./create-release.sh <appimage-version> [claude-version]
# Examples:
#   ./create-release.sh 1.0.1                    # New AppImage version, keep current Claude version
#   ./create-release.sh 1.1.0 0.9.4             # New AppImage version with new Claude version
#   ./create-release.sh 1.0.2 --claude-only     # Only update AppImage version for fixes/improvements

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_usage() {
    echo "Usage: $0 <appimage-version> [claude-version|--claude-only]"
    echo
    echo "Examples:"
    echo "  $0 1.0.1                    # New AppImage version, keep current Claude version"
    echo "  $0 1.1.0 0.9.4             # New AppImage version with new Claude version"
    echo "  $0 1.0.2 --claude-only     # Only update AppImage version (for fixes/improvements)"
    echo
    echo "Arguments:"
    echo "  appimage-version    : Version for your AppImage release (semantic versioning: x.y.z)"
    echo "  claude-version      : (Optional) Claude Desktop version to use"
    echo "  --claude-only       : Only update AppImage version, don't change Claude version"
}

# Check if version argument is provided
if [ $# -eq 0 ]; then
    print_error "No arguments provided"
    show_usage
    exit 1
fi

NEW_APPIMAGE_VERSION="$1"
NEW_CLAUDE_VERSION=""
CLAUDE_ONLY=false

# Parse second argument
if [ $# -gt 1 ]; then
    if [ "$2" == "--claude-only" ]; then
        CLAUDE_ONLY=true
    else
        NEW_CLAUDE_VERSION="$2"
    fi
fi

BUILD_FUNCTIONS_FILE="scripts/build-functions.sh"

# Validate AppImage version format (semantic versioning: x.y.z)
if ! [[ "$NEW_APPIMAGE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "Invalid AppImage version format. Please use semantic versioning (e.g., 1.0.1)"
    exit 1
fi

# Validate Claude version format if provided
if [ -n "$NEW_CLAUDE_VERSION" ] && ! [[ "$NEW_CLAUDE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "Invalid Claude version format. Please use semantic versioning (e.g., 0.9.4)"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "$BUILD_FUNCTIONS_FILE" ]; then
    print_error "build-functions.sh not found. Please run this script from the project root directory."
    exit 1
fi

# Check if git repository is clean
if ! git diff-index --quiet HEAD --; then
    print_error "Git repository has uncommitted changes. Please commit or stash them first."
    exit 1
fi

# Check if we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    print_warning "You're not on the main branch (currently on: $CURRENT_BRANCH)"
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Release creation cancelled."
        exit 0
    fi
fi

# Get current versions from build-functions.sh
CURRENT_CLAUDE_VERSION=$(grep '^CLAUDE_VERSION=' "$BUILD_FUNCTIONS_FILE" | cut -d'"' -f2)
CURRENT_APPIMAGE_VERSION=$(grep '^APPIMAGE_VERSION=' "$BUILD_FUNCTIONS_FILE" | cut -d'"' -f2)

print_info "Current Claude Desktop version: $CURRENT_CLAUDE_VERSION"
print_info "Current AppImage version: $CURRENT_APPIMAGE_VERSION"
print_info "New AppImage version: $NEW_APPIMAGE_VERSION"

if [ -n "$NEW_CLAUDE_VERSION" ]; then
    print_info "New Claude Desktop version: $NEW_CLAUDE_VERSION"
elif [ "$CLAUDE_ONLY" = true ]; then
    print_info "Claude Desktop version: $CURRENT_CLAUDE_VERSION (unchanged)"
    NEW_CLAUDE_VERSION="$CURRENT_CLAUDE_VERSION"
else
    print_info "Claude Desktop version: $CURRENT_CLAUDE_VERSION (unchanged)"
    NEW_CLAUDE_VERSION="$CURRENT_CLAUDE_VERSION"
fi

# Check if AppImage tag already exists
if git tag -l | grep -q "^v$NEW_APPIMAGE_VERSION$"; then
    print_error "Tag v$NEW_APPIMAGE_VERSION already exists!"
    exit 1
fi

# Determine release type
RELEASE_TYPE=""
if [ "$NEW_CLAUDE_VERSION" != "$CURRENT_CLAUDE_VERSION" ]; then
    RELEASE_TYPE="Claude Desktop update (v$CURRENT_CLAUDE_VERSION → v$NEW_CLAUDE_VERSION)"
else
    RELEASE_TYPE="AppImage improvements/fixes"
fi

# Confirm the action
echo
print_warning "This will create release v$NEW_APPIMAGE_VERSION:"
echo "  • AppImage version: $CURRENT_APPIMAGE_VERSION → $NEW_APPIMAGE_VERSION"
echo "  • Claude Desktop version: $CURRENT_CLAUDE_VERSION → $NEW_CLAUDE_VERSION"
echo "  • Release type: $RELEASE_TYPE"
echo
echo "Actions:"
echo "  1. Update versions in $BUILD_FUNCTIONS_FILE"
echo "  2. Commit the changes"
echo "  3. Create and push git tag v$NEW_APPIMAGE_VERSION"
echo "  4. Trigger GitHub Actions to build and create a release"
echo
read -p "Do you want to continue? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Release creation cancelled."
    exit 0
fi

# Update versions in build-functions.sh
print_info "Updating versions in $BUILD_FUNCTIONS_FILE..."

# Update AppImage version
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS sed syntax
    sed -i '' "s/^APPIMAGE_VERSION=\".*\"/APPIMAGE_VERSION=\"$NEW_APPIMAGE_VERSION\"/" "$BUILD_FUNCTIONS_FILE"
    if [ -n "$NEW_CLAUDE_VERSION" ] && [ "$NEW_CLAUDE_VERSION" != "$CURRENT_CLAUDE_VERSION" ]; then
        sed -i '' "s/^CLAUDE_VERSION=\".*\"/CLAUDE_VERSION=\"$NEW_CLAUDE_VERSION\"/" "$BUILD_FUNCTIONS_FILE"
    fi
else
    # Linux sed syntax
    sed -i "s/^APPIMAGE_VERSION=\".*\"/APPIMAGE_VERSION=\"$NEW_APPIMAGE_VERSION\"/" "$BUILD_FUNCTIONS_FILE"
    if [ -n "$NEW_CLAUDE_VERSION" ] && [ "$NEW_CLAUDE_VERSION" != "$CURRENT_CLAUDE_VERSION" ]; then
        sed -i "s/^CLAUDE_VERSION=\".*\"/CLAUDE_VERSION=\"$NEW_CLAUDE_VERSION\"/" "$BUILD_FUNCTIONS_FILE"
    fi
fi

# Verify the changes were made
NEW_APPIMAGE_VERSION_CHECK=$(grep '^APPIMAGE_VERSION=' "$BUILD_FUNCTIONS_FILE" | cut -d'"' -f2)
NEW_CLAUDE_VERSION_CHECK=$(grep '^CLAUDE_VERSION=' "$BUILD_FUNCTIONS_FILE" | cut -d'"' -f2)

if [ "$NEW_APPIMAGE_VERSION_CHECK" != "$NEW_APPIMAGE_VERSION" ]; then
    print_error "Failed to update AppImage version in $BUILD_FUNCTIONS_FILE"
    exit 1
fi

if [ "$NEW_CLAUDE_VERSION_CHECK" != "$NEW_CLAUDE_VERSION" ]; then
    print_error "Failed to update Claude version in $BUILD_FUNCTIONS_FILE"
    exit 1
fi

print_success "Versions updated in $BUILD_FUNCTIONS_FILE"

# Create commit message
COMMIT_MESSAGE="Release v$NEW_APPIMAGE_VERSION"
if [ "$NEW_CLAUDE_VERSION" != "$CURRENT_CLAUDE_VERSION" ]; then
    COMMIT_MESSAGE="$COMMIT_MESSAGE: Update to Claude Desktop v$NEW_CLAUDE_VERSION"
else
    COMMIT_MESSAGE="$COMMIT_MESSAGE: AppImage improvements and fixes"
fi

# Stage and commit the change
print_info "Committing version changes..."
git add "$BUILD_FUNCTIONS_FILE"
git commit -m "$COMMIT_MESSAGE"

print_success "Changes committed"

# Create tag message
TAG_MESSAGE="Release v$NEW_APPIMAGE_VERSION

AppImage version: $NEW_APPIMAGE_VERSION
Claude Desktop version: $NEW_CLAUDE_VERSION
Release type: $RELEASE_TYPE

Changes:
- AppImage version updated to $NEW_APPIMAGE_VERSION"

if [ "$NEW_CLAUDE_VERSION" != "$CURRENT_CLAUDE_VERSION" ]; then
    TAG_MESSAGE="$TAG_MESSAGE
- Claude Desktop updated to v$NEW_CLAUDE_VERSION"
else
    TAG_MESSAGE="$TAG_MESSAGE
- AppImage improvements and bug fixes"
fi

TAG_MESSAGE="$TAG_MESSAGE
- Built from commit $(git rev-parse HEAD)

Download Instructions:
1. Download the AppImage from the release assets
2. Make it executable: chmod +x Claude-$NEW_APPIMAGE_VERSION-claude-$NEW_CLAUDE_VERSION-*.AppImage
3. Run it: ./Claude-$NEW_APPIMAGE_VERSION-claude-$NEW_CLAUDE_VERSION-*.AppImage

This AppImage is self-contained and includes the Electron runtime - no additional dependencies required."

# Create and push the tag
print_info "Creating tag v$NEW_APPIMAGE_VERSION..."
git tag -a "v$NEW_APPIMAGE_VERSION" -m "$TAG_MESSAGE"

print_success "Tag v$NEW_APPIMAGE_VERSION created"

# Push changes and tag
print_info "Pushing changes and tag to origin..."
git push origin "$CURRENT_BRANCH"
git push origin "v$NEW_APPIMAGE_VERSION"

print_success "Tag and changes pushed to origin"

echo
print_success "🎉 Release v$NEW_APPIMAGE_VERSION created successfully!"
echo
print_info "Release Details:"
echo "  • AppImage Version: $NEW_APPIMAGE_VERSION"
echo "  • Claude Desktop Version: $NEW_CLAUDE_VERSION"
echo "  • Release Type: $RELEASE_TYPE"
echo
print_info "Next steps:"
echo "  1. GitHub Actions will automatically build the AppImage"
echo "  2. A new release will be created at: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/releases"
echo "  3. The AppImage will be attached to the release when the build completes"
echo
print_info "You can monitor the build progress at:"
echo "  https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/actions"
echo
print_info "Expected AppImage filename: Claude-$NEW_APPIMAGE_VERSION-claude-$NEW_CLAUDE_VERSION-*.AppImage"