#!/usr/bin/env bash
set -euo pipefail

bash tool/check_shorebird.sh
mode="${1:-}"
case "$mode" in
  release|validate-release)
    [[ "${BUILD_NAME:-}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Invalid BUILD_NAME'; exit 1; }
    [[ "${SHOREBIRD_BUILD_NUMBER:-}" =~ ^[1-9][0-9]*$ ]] || {
      echo "Uygulama surumu: $BUILD_NAME. build_number alanina yalnizca pozitif tam sayi gir (ornegin 38); surum numarasini yazma."
      exit 1
    }
    target_version="$BUILD_NAME+$SHOREBIRD_BUILD_NUMBER"
    if [[ "$mode" == validate-release ]]; then
      echo "Uygulama surumu: $BUILD_NAME; derleme numarasi: $SHOREBIRD_BUILD_NUMBER"
      exit 0
    fi
    ;;
  patch|validate-patch)
    [[ "${RELEASE_VERSION:-}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]] || { echo 'Enter the exact release_version, including +build number.'; exit 1; }
    [[ "${PATCH_TRACK:-}" == staging || "${PATCH_TRACK:-}" == stable ]] || { echo 'Invalid patch track'; exit 1; }
    # Environment values are strings. Accept boolean casing from CI/API
    # callers and trim surrounding whitespace, including CRLF line endings.
    dry_run_value="${PATCH_DRY_RUN:-}"
    dry_run_value="${dry_run_value#"${dry_run_value%%[![:space:]]*}"}"
    dry_run_value="${dry_run_value%"${dry_run_value##*[![:space:]]}"}"
    case "$dry_run_value" in
      [Tt][Rr][Uu][Ee]) PATCH_DRY_RUN=true ;;
      [Ff][Aa][Ll][Ss][Ee]) PATCH_DRY_RUN=false ;;
      *) echo 'Invalid dry_run value. Select true (validate only) or false (publish). Empty or unresolved values are not accepted.' >&2; exit 1 ;;
    esac
    test -f ios/Podfile.lock || { echo 'Restore pubspec.lock and ios/Podfile.lock from the release build artifacts first.'; exit 1; }
    target_version="$RELEASE_VERSION"
    if [[ "$mode" == validate-patch ]]; then
      echo "Patch target: $target_version; track: $PATCH_TRACK; dry_run: $PATCH_DRY_RUN"
      exit 0
    fi
    ;;
  *) echo 'Usage: bash tool/shorebird_codemagic.sh release|validate-release|patch|validate-patch'; exit 1 ;;
esac

# Optional overrides must stay identical for the release and all its patches.
# With no overrides, retain the existing defaults compiled into the Dart code.
dart_args=(--)
for key_name in REVENUECAT_IOS_API_KEY REVENUECAT_ANDROID_API_KEY; do
  if [[ -n "${!key_name:-}" ]]; then
    dart_args+=("--dart-define=$key_name=${!key_name}")
  fi
done

mkdir -p shorebird-build-info/ios
{
  echo "Mode: $mode"
  echo "Release: $target_version"
  echo "Source commit: ${CM_COMMIT:-unknown}"
  if [[ "$mode" == patch ]]; then
    echo "Track: $PATCH_TRACK; dry run: $PATCH_DRY_RUN"
  fi
  xcodebuild -version
  pod --version
  shorebird --version
} > shorebird-build-info/build.txt

if [[ "$mode" == release ]]; then
  shorebird release ios --confirm \
    --build-name="$BUILD_NAME" --build-number="$SHOREBIRD_BUILD_NUMBER" \
    --export-options-plist="$HOME/export_options.plist" "${dart_args[@]}"
else
  patch_args=(--confirm)
  if [[ "$PATCH_DRY_RUN" == true ]]; then
    patch_args+=(--dry-run)
  fi
  shorebird patch ios \
    --release-version="$RELEASE_VERSION" --track="$PATCH_TRACK" \
    --export-options-plist="$HOME/export_options.plist" "${patch_args[@]}" "${dart_args[@]}"
fi

cp pubspec.lock shorebird-build-info/pubspec.lock
cp ios/Podfile.lock shorebird-build-info/ios/Podfile.lock
cp shorebird.yaml shorebird-build-info/shorebird.yaml
echo "Shorebird $mode completed for $target_version."
