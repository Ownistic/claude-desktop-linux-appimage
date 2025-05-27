#!/bin/bash

# Script to create a new release by updating the Claude version and creating a git tag
# Usage: ./create-release.sh <version>
# Example: ./create-release.sh 0.9.4

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

# Check if version argument is provided
if [ $# -eq 0 ]; then
    print_error "No version argument provided"
    echo "Usage: $0 <version>"
    echo "Example: $0 0.9.4"
    exit 1
fi

NEW_VERSION="$1"
BUILD_FUNCTIONS_FILE="scripts/build-functions.sh"

# Validate version format (semantic versioning: x.y.z)
if ! [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "Invalid version format. Please use semantic versioning (e.g., 0.9.4)"
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

# Get current version from build-functions.sh
CURRENT_VERSION=$(grep '^CLAUDE_VERSION=' "$BUILD_FUNCTIONS_FILE" | cut -d'"' -f2)
print_info "Current version: $CURRENT_VERSION"
print_info "New version: $NEW_VERSION"

# Check if tag already exists
if git tag -l | grep -q "^v$NEW_VERSION$"; then
    print_error "Tag v$NEW_VERSION already exists!"
    exit 1
fi

# Confirm the action
echo
print_warning "This will:"
echo "  1. Update CLAUDE_VERSION in $BUILD_FUNCTIONS_FILE from $CURRENT_VERSION to $NEW_VERSION"
echo "  2. Commit the change"
echo "  3. Create and push git tag v$NEW_VERSION"
echo "  4. Trigger GitHub Actions to build and create a release"
echo
read -p "Do you want to continue? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Release creation cancelled."
    exit 0
fi

# Update version in build-functions.sh
print_info "Updating version in $BUILD_FUNCTIONS_FILE..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS sed syntax
    sed -i '' "s/^CLAUDE_VERSION=\".*\"/CLAUDE_VERSION=\"$NEW_VERSION\"/" "$BUILD_FUNCTIONS_FILE"
else
    # Linux sed syntax
    sed -i "s/^CLAUDE_VERSION=\".*\"/CLAUDE_VERSION=\"$NEW_VERSION\"/" "$BUILD_FUNCTIONS_FILE"
fi

# Verify the change was made
NEW_VERSION_CHECK=$(grep '^CLAUDE_VERSION=' "$BUILD_FUNCTIONS_FILE" | cut -d'"' -f2)
if [ "$NEW_VERSION_CHECK" != "$NEW_VERSION" ]; then
    print_error "Failed to update version in $BUILD_FUNCTIONS_FILE"
    exit 1
fi

print_success "Version updated in $BUILD_FUNCTIONS_FILE"

# Stage and commit the change
print_info "Committing version change..."
git add "$BUILD_FUNCTIONS_FILE"
git commit -m "Release v$NEW_VERSION: Update Claude version to $NEW_VERSION"

print_success "Changes committed"

# Create and push the tag
print_info "Creating tag v$NEW_VERSION..."
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION

Claude Desktop AppImage build for version $NEW_VERSION

Changes:
- Updated Claude version to $NEW_VERSION
- Built from commit $(git rev-parse HEAD)

Download the AppImage from the release assets and make it executable:
chmod +x Claude-$NEW_VERSION-*.AppImage
./Claude-$NEW_VERSION-*.AppImage"

print_success "Tag v$NEW_VERSION created"

# Push changes and tag
print_info "Pushing changes and tag to origin..."
git push origin "$CURRENT_BRANCH"
git push origin "v$NEW_VERSION"

print_success "Tag and changes pushed to origin"

echo
print_success "🎉 Release v$NEW_VERSION created successfully!"
echo
print_info "Next steps:"
echo "  1. GitHub Actions will automatically build the AppImage"
echo "  2. A new release will be created at: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/releases"
echo "  3. The AppImage will be attached to the release when the build completes"
echo
print_info "You can monitor the build progress at:"
echo "  https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/actions"
