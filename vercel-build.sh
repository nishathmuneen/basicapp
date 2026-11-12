#!/usr/bin/env bash
set -euo pipefail

FLUTTER_DIR="${HOME}/flutter"
if [ ! -x "${FLUTTER_DIR}/bin/flutter" ]; then
  git clone --depth 1 --branch 3.47.9 https://github.com/flutter/flutter.git "${FLUTTER_DIR}"
fi

git config --global --add safe.directory "${FLUTTER_DIR}" || true
export PATH="${FLUTTER_DIR}/bin:${PATH}"

flutter config --enable-web --no-analytics
cd flutter_app
flutter pub get
flutter build web --release --no-pub
