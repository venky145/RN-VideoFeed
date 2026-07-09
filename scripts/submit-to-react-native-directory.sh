#!/usr/bin/env bash
set -euo pipefail

# Submits rn-videofeed to https://reactnative.directory via PR to
# react-native-community/directory. Requires: gh auth login

ENTRY='{
    "githubUrl": "https://github.com/venky145/RN-VideoFeed",
    "npmPkg": "rn-videofeed",
    "examples": [
      "https://github.com/venky145/RN-VideoFeed/tree/main/VideoFeedSample"
    ],
    "ios": true,
    "android": true
  }'

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI not logged in. Run: gh auth login -h github.com -p ssh -w"
  exit 1
fi

echo "Forking react-native-community/directory (if needed)..."
gh repo fork react-native-community/directory --clone --remote=true -- "$WORKDIR"
cd "$WORKDIR"

git checkout -b add-rn-videofeed

python3 - <<'PY' "$ENTRY"
import json, sys
entry = json.loads(sys.argv[1])
with open("react-native-libraries.json", encoding="utf-8") as f:
    libs = json.load(f)
for lib in libs:
    if lib.get("npmPkg") == entry.get("npmPkg") or lib.get("githubUrl", "").rstrip("/").lower().endswith("/rn-videofeed"):
        print("Already listed in react-native-libraries.json")
        sys.exit(0)
libs.append(entry)
with open("react-native-libraries.json", "w", encoding="utf-8") as f:
    json.dump(libs, f, indent=2)
    f.write("\n")
PY

git add react-native-libraries.json
git commit -m "$(cat <<'EOF'
Add rn-videofeed to React Native Directory

Native vertical video feed (Reels/TikTok style) for iOS and Android.
EOF
)"

git push -u origin add-rn-videofeed

gh pr create \
  --repo react-native-community/directory \
  --title "Add rn-videofeed" \
  --body "$(cat <<'EOF'
Adds **rn-videofeed** — native vertical full-screen video feed for React Native (Reels/TikTok style).

- npm: https://www.npmjs.com/package/rn-videofeed
- GitHub: https://github.com/venky145/RN-VideoFeed
- Example: https://github.com/venky145/RN-VideoFeed/tree/main/VideoFeedSample
- iOS (AVPlayer) + Android (ExoPlayer)
EOF
)"

echo "Done. PR created for react-native-community/directory"
