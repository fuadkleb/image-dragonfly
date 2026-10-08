#!/usr/bin/env bash
set -euo pipefail

source_image='docker.dragonflydb.io/dragonflydb/dragonfly'
target_image="${TARGET_IMAGE:-registry.pauddasmen.id/dragonfly}"
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

# Read registry tags directly, so releases without published images are ignored.
crane ls "$source_image" > "$work_dir/tags"
# Select the highest numeric (major, minor, patch) version for each major.
# Keep the original upstream tag; prefer v-prefixed tags if both forms exist.
python3 - "$work_dir/tags" > "$work_dir/versions" <<'PY'
import re
import sys

latest = {}
with open(sys.argv[1]) as tags:
    for line in tags:
        tag = line.strip()
        match = re.fullmatch(r"v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", tag)
        if not match:
            continue
        version = tuple(map(int, match.groups()))
        candidate = (version, tag.startswith("v"), tag)
        major = version[0]
        if major not in latest or candidate > latest[major]:
            latest[major] = candidate
for major in sorted(latest):
    print(latest[major][2])
PY

versions=()
while IFS= read -r tag; do
  versions+=("$tag")
done < "$work_dir/versions"
if (( ${#versions[@]} == 0 )); then
  echo 'Tidak ditemukan tag rilis stabil pada registry upstream.' >&2
  exit 1
fi

copied=0
skipped=0
# Publish upstream latest last, after the newest stable release of each major.
for tag in "${versions[@]}" latest; do
  source_digest=$(crane digest "$source_image:$tag")
  if target_digest=$(crane digest "$target_image:$tag" 2> "$work_dir/error"); then
    if [[ "$target_digest" == "$source_digest" ]]; then
      echo "Sudah sama: $target_image:$tag"
      skipped=$((skipped + 1))
      continue
    fi
  elif ! grep -Eqi 'MANIFEST_UNKNOWN|NAME_UNKNOWN|404 Not Found' "$work_dir/error"; then
    # Authentication, network, and server failures must not be treated as missing tags.
    cat "$work_dir/error" >&2
    exit 1
  fi

  # Pin the source digest to avoid a moving tag changing during the copy.
  # crane copies the complete multi-platform manifest without rebuilding it.
  crane copy "$source_image@$source_digest" "$target_image:$tag"
  target_digest=$(crane digest "$target_image:$tag")
  if [[ "$target_digest" != "$source_digest" ]]; then
    echo "Digest hasil copy tidak sama untuk $tag" >&2
    exit 1
  fi
  copied=$((copied + 1))
done

summary="Selesai: $copied tag disalin, $skipped tag sudah sama."
echo "$summary"
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  printf '%s\n' "$summary" >> "$GITHUB_STEP_SUMMARY"
fi
