#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

jq -e '
  .schemaVersion == 1 and
  .id == "io.github.joshferrara.quick-emoji" and
  (.kinds == ["service"]) and
  .entryPoints.service == "Service.qml"
' "$root/manifest.json" >/dev/null

[[ $(wc -l <"$root/data/emojis.tsv") -ge 1800 ]]
awk -F '\t' 'NF != 4 || $1 == "" || $2 == "" { exit 1 }' "$root/data/emojis.tsv"

lookup() {
  local alias=$1 expected=$2
  awk -F '\t' -v alias="$alias" -v expected="$expected" '
    BEGIN { found = 0 }
    {
      count = split($3, aliases, ",")
      for (i = 1; i <= count; i++) {
        if (aliases[i] == alias && $1 == expected) found = 1
      }
    }
    END { exit found ? 0 : 1 }
  ' "$root/data/emojis.tsv"
}

lookup wave 👋
lookup thumbsup 👍
lookup heart ❤️
lookup tada 🎉
lookup rocket 🚀

bash -n "$root/scripts/manage.sh"
shellcheck "$root/scripts/manage.sh" "$root/tests/test_repository.sh"

echo "repository checks passed"
