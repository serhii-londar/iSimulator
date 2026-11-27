#!/usr/bin/env bash

# ==============================================================================
# iSimulator Release Build & GitHub Publish Script
# ==============================================================================
# Usage:
#   ./scripts/publish_release.sh <version> [options]
#
# Examples:
#   ./scripts/publish_release.sh 3.4.0
#   ./scripts/publish_release.sh v3.4.0 --draft
#   ./scripts/publish_release.sh 3.4.0 --notes "Added new feature X"
#   ./scripts/publish_release.sh 3.4.0 --dry-run
# ==============================================================================

set -eo pipefail

# Print styled messages
info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
success() { echo -e "\033[1;32m[SUCCESS]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARNING]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; exit 1; }

# Usage help
show_help() {
    cat << EOF
Usage: $(basename "$0") [version] [options]

Builds iSimulator macOS app in Release mode, packages it into a zip file,
creates a Git tag, and publishes a new release on GitHub.

Arguments:
  [version]             Optional. Target release version (e.g. 4.0.0 or v4.0.0).
                        If omitted, version is automatically read from Xcode project (MARKETING_VERSION).

Options:
  --notes <text>          Release notes text
  --notes-file <file>     Path to file containing release notes
  --draft                 Save release as draft on GitHub
  --prerelease            Mark release as pre-release on GitHub
  --skip-tag              Skip git tag creation and pushing
  --sign-identity <name>  Developer ID Application signing identity (or set DEVELOPER_ID_APPLICATION)
  --notarize              Notarize and staple the app using xcrun notarytool
  --dry-run               Build and package without creating Git tag or GitHub release
  -h, --help              Show this help message

Notarization Environment Variables:
  DEVELOPER_ID_APPLICATION   Signing identity (e.g. "Developer ID Application: Name (TEAMID)")
  Option 1 (App Store Connect API Key):
    NOTARY_KEY_ID            App Store Connect API Key ID
    NOTARY_ISSUER_ID         App Store Connect Issuer ID
    NOTARY_KEY_PATH          Path to .p8 private key file (or NOTARY_KEY_BASE64)
  Option 2 (Apple ID):
    APPLE_ID                 Apple ID email
    APPLE_TEAM_ID            Apple Developer Team ID
    APPLE_APP_PASSWORD       App-specific password
  Option 3 (Keychain Profile):
    NOTARY_KEYCHAIN_PROFILE  Profile name stored via 'xcrun notarytool store-credentials'

Examples:
  ./scripts/publish_release.sh                # Auto-detects version from Xcode project
  ./scripts/publish_release.sh 4.0.0
  ./scripts/publish_release.sh --dry-run
EOF
    exit 0
}

# Parse parameters
VERSION=""
RELEASE_NOTES=""
RELEASE_NOTES_FILE=""
IS_DRAFT=false
IS_PRERELEASE=false
SKIP_TAG=false
DRY_RUN=false
SIGN_IDENTITY="${DEVELOPER_ID_APPLICATION:-}"
NOTARIZE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            ;;
        --notes)
            RELEASE_NOTES="$2"
            shift 2
            ;;
        --notes-file)
            RELEASE_NOTES_FILE="$2"
            shift 2
            ;;
        --draft)
            IS_DRAFT=true
            shift
            ;;
        --prerelease)
            IS_PRERELEASE=true
            shift
            ;;
        --skip-tag)
            SKIP_TAG=true
            shift
            ;;
        --sign-identity)
            SIGN_IDENTITY="$2"
            shift 2
            ;;
        --notarize)
            NOTARIZE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -*)
            error "Unknown option: $1. Use --help for usage instructions."
            ;;
        *)
            if [[ -z "$VERSION" ]]; then
                VERSION="$1"
            else
                error "Unexpected argument: $1"
            fi
            shift
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -z "$VERSION" ]]; then
    DETECTED_VERSION=$(sed -n 's/.*MARKETING_VERSION = \(.*\);/\1/p' "$REPO_ROOT/iSimulator.xcodeproj/project.pbxproj" 2>/dev/null | head -n 1 | tr -d ' ')
    if [[ -n "$DETECTED_VERSION" ]]; then
        VERSION="$DETECTED_VERSION"
        info "Auto-detected version from Xcode project: $VERSION"
    else
        error "Version argument omitted and could not auto-detect MARKETING_VERSION from Xcode project. Usage: ./scripts/publish_release.sh [version]"
    fi
fi

# Ensure version format
if [[ "$VERSION" =~ ^v[0-9]+ ]]; then
    TAG_NAME="$VERSION"
    RAW_VERSION="${VERSION#v}"
else
    TAG_NAME="v$VERSION"
    RAW_VERSION="$VERSION"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$REPO_ROOT/build"
ZIP_NAME="iSimulator.zip"
VERSIONED_ZIP_NAME="iSimulator-${RAW_VERSION}.zip"

cd "$REPO_ROOT"

info "Preparing release for iSimulator ${TAG_NAME}..."

# Check prerequisites
info "Checking prerequisites..."
command -v xcodebuild >/dev/null 2>&1 || error "xcodebuild tool is required but not installed."
command -v git >/dev/null 2>&1 || error "git is required but not installed."
command -v ditto >/dev/null 2>&1 || error "ditto tool is required but not installed."

if [[ "$DRY_RUN" == false ]]; then
    command -v gh >/dev/null 2>&1 || error "GitHub CLI (gh) is required to publish releases. Install with: brew install gh"
    if ! gh auth status >/dev/null 2>&1; then
        error "GitHub CLI is not authenticated. Run 'gh auth login' to authenticate."
    fi
fi

# Step 1: Clean & Build Release App
info "Building iSimulator in Release configuration..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

xcodebuild -project "$REPO_ROOT/iSimulator.xcodeproj" \
    -scheme "iSimulator" \
    -configuration "Release" \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    clean build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    > "$BUILD_DIR/build.log" 2>&1 || {
        cat "$BUILD_DIR/build.log"
        error "xcodebuild failed. Check build logs above."
    }

APP_PATH="$BUILD_DIR/DerivedData/Build/Products/Release/iSimulator.app"

if [[ ! -d "$APP_PATH" ]]; then
    error "Built app not found at path: $APP_PATH"
fi

success "Successfully built iSimulator.app"

# Step 2: Code Sign, Notarize & Package
has_notary_credentials() {
    [[ -n "${NOTARY_KEYCHAIN_PROFILE:-}" ]] && return 0
    [[ -n "${NOTARY_KEY_ID:-}" && -n "${NOTARY_ISSUER_ID:-}" && ( -n "${NOTARY_KEY_PATH:-}" || -n "${NOTARY_KEY_BASE64:-}" ) ]] && return 0
    [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APPLE_APP_PASSWORD:-}" ]] && return 0
    return 1
}

if [[ "$NOTARIZE" == false && -n "$SIGN_IDENTITY" ]] && has_notary_credentials; then
    NOTARIZE=true
fi

if [[ -n "$SIGN_IDENTITY" && "$SIGN_IDENTITY" != "-" ]]; then
    info "Signing application with Developer ID: $SIGN_IDENTITY..."
    codesign --force --deep --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_PATH"
    codesign --verify --deep --strict --verbose=2 "$APP_PATH"
    success "Successfully signed iSimulator.app"
else
    if [[ "$NOTARIZE" == true ]]; then
        error "Notarization requires a Developer ID Application signing identity (--sign-identity or DEVELOPER_ID_APPLICATION)."
    fi
    info "Signing application (ad-hoc)..."
    codesign --force --deep --sign - "$APP_PATH" || warn "Ad-hoc code signing failed, proceeding anyway."
fi

if [[ "$NOTARIZE" == true ]]; then
    info "Notarizing iSimulator.app..."
    NOTARY_ZIP="$BUILD_DIR/iSimulator-notarize.zip"
    TEMP_KEY_FILE=""

    cleanup_notary() {
        rm -f "$NOTARY_ZIP"
        if [[ -n "$TEMP_KEY_FILE" && -f "$TEMP_KEY_FILE" ]]; then
            rm -f "$TEMP_KEY_FILE"
        fi
    }
    trap cleanup_notary EXIT

    ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$NOTARY_ZIP"

    NOTARY_ARGS=("submit" "$NOTARY_ZIP" "--wait")
    if [[ -n "${NOTARY_KEYCHAIN_PROFILE:-}" ]]; then
        NOTARY_ARGS+=("--keychain-profile" "$NOTARY_KEYCHAIN_PROFILE")
    elif [[ -n "${NOTARY_KEY_ID:-}" && -n "${NOTARY_ISSUER_ID:-}" && ( -n "${NOTARY_KEY_PATH:-}" || -n "${NOTARY_KEY_BASE64:-}" ) ]]; then
        KEY_FILE="${NOTARY_KEY_PATH:-}"
        if [[ -z "$KEY_FILE" && -n "${NOTARY_KEY_BASE64:-}" ]]; then
            TEMP_KEY_FILE="$BUILD_DIR/AuthKey_${NOTARY_KEY_ID}.p8"
            echo "$NOTARY_KEY_BASE64" | base64 --decode > "$TEMP_KEY_FILE"
            KEY_FILE="$TEMP_KEY_FILE"
        fi
        NOTARY_ARGS+=("--key" "$KEY_FILE" "--key-id" "$NOTARY_KEY_ID" "--issuer" "$NOTARY_ISSUER_ID")
    elif [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APPLE_APP_PASSWORD:-}" ]]; then
        NOTARY_ARGS+=("--apple-id" "$APPLE_ID" "--team-id" "$APPLE_TEAM_ID" "--password" "$APPLE_APP_PASSWORD")
    else
        error "Notarization requested, but no notarization credentials were provided."
    fi

    xcrun notarytool "${NOTARY_ARGS[@]}"
    success "Notarization succeeded!"

    info "Stapling notarization ticket to iSimulator.app..."
    xcrun stapler staple "$APP_PATH"
    xcrun stapler validate "$APP_PATH"
    spctl --assess --type execute --verbose "$APP_PATH"
    success "Stapled and verified iSimulator.app"

    cleanup_notary
    trap - EXIT
fi

info "Creating zip archives..."
cd "$BUILD_DIR/DerivedData/Build/Products/Release"
ditto -c -k --sequesterRsrc --keepParent "iSimulator.app" "$BUILD_DIR/$ZIP_NAME"
cp "$BUILD_DIR/$ZIP_NAME" "$BUILD_DIR/$VERSIONED_ZIP_NAME"
cd "$REPO_ROOT"

success "Package archives created: $ZIP_NAME and $VERSIONED_ZIP_NAME"

if [[ "$DRY_RUN" == true ]]; then
    warn "Dry-run mode active. Skipping git tag and GitHub release step."
    info "Generated files in temporary build location:"
    ls -lh "$BUILD_DIR/$ZIP_NAME" "$BUILD_DIR/$VERSIONED_ZIP_NAME"
    success "Dry run complete!"
    exit 0
fi

# Step 3: Git Tagging
if [[ "$SKIP_TAG" == false ]]; then
    if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
        info "Git tag $TAG_NAME already exists locally."
    else
        info "Creating Git tag $TAG_NAME..."
        git tag -a "$TAG_NAME" -m "Release $TAG_NAME"
    fi

    if git ls-remote --tags origin | grep -q "refs/tags/$TAG_NAME"; then
        info "Git tag $TAG_NAME already exists on remote origin."
    else
        info "Pushing Git tag $TAG_NAME to remote origin..."
        git push origin "$TAG_NAME"
    fi
fi

# Step 4: Create GitHub Release
info "Publishing release to GitHub..."

GH_FLAGS=()
if [[ "$IS_DRAFT" == true ]]; then
    GH_FLAGS+=("--draft")
fi
if [[ "$IS_PRERELEASE" == true ]]; then
    GH_FLAGS+=("--prerelease")
fi
if [[ -n "$RELEASE_NOTES" ]]; then
    GH_FLAGS+=("--notes" "$RELEASE_NOTES")
elif [[ -n "$RELEASE_NOTES_FILE" ]]; then
    GH_FLAGS+=("--notes-file" "$RELEASE_NOTES_FILE")
else
    GH_FLAGS+=("--generate-notes")
fi

gh release create "$TAG_NAME" \
    "$BUILD_DIR/$ZIP_NAME" \
    "$BUILD_DIR/$VERSIONED_ZIP_NAME" \
    --title "$TAG_NAME" \
    "${GH_FLAGS[@]}"

success "Release $TAG_NAME published successfully to GitHub!"
