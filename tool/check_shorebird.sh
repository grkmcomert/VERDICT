#!/usr/bin/env bash
set -euo pipefail

# Run from the repository root. No account credentials are printed.
if [[ -z "${SHOREBIRD_TOKEN:-}" ]]; then
  echo 'Missing SHOREBIRD_TOKEN CI secret (Codemagic group: shorebird). See docs/shorebird.md.' >&2
  exit 1
fi
if [[ ! -f shorebird.yaml ]]; then
  echo 'Missing shorebird.yaml. Include the existing VERDICT configuration in the build source.' >&2
  exit 1
fi
if ! grep -Eq '^app_id: [0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}[[:space:]]*$' shorebird.yaml; then
  echo 'shorebird.yaml must contain the real app_id created by shorebird init.' >&2
  exit 1
fi
if ! grep -Eq '^[[:space:]]+- shorebird\.yaml[[:space:]]*$' pubspec.yaml; then
  echo 'Add shorebird.yaml to flutter.assets in pubspec.yaml.' >&2
  exit 1
fi
if grep -Eq '^auto_update:[[:space:]]*false' shorebird.yaml; then
  echo 'Automatic updates must remain enabled for this application.' >&2
  exit 1
fi
