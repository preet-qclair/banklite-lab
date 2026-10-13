#!/bin/bash
# Facilitator script: runs every lab step end to end and writes the fallback outputs.
# Participants do these steps by hand; this is for rehearsal and for out/solutions.
set -u
OUT=${1:-/lab/out}
mkdir -p "$OUT"
t() { local s=$(date +%s); "$@"; echo "   ($(( $(date +%s) - s ))s)"; }

echo "== Lab 1: network side"
t sh -c "openssl s_client -connect localhost:8443 -groups X25519MLKEM768:X25519 </dev/null 2>/dev/null \
  | grep -E 'Negotiated|Cipher is|Peer signature type|subject=' > '$OUT/lab1_8443.txt'"
t sh -c "testssl --quiet --color 0 --warnings off -p -P -f -S localhost:8444 > '$OUT/lab1_testssl_8444.txt' 2>&1"
cp /lab/templates/network.json "$OUT/network.template.json"

echo "== Lab 2: file and code side"
t sh -c "cbomkit-theia dir /banklite > '$OUT/files.json' 2> '$OUT/theia.log'"
t sh -c "cdxgen --include-crypto --no-install-deps -o '$OUT/code.json' /banklite > '$OUT/cdxgen.log' 2>&1"

echo "== Lab 3: merge, validate, score"
NET=${NETWORK_CBOM:-/lab/answer-key/network.solution.json}
[ -f "$NET" ] || NET="$OUT/network.template.json"
t sh -c "cyclonedx merge --input-files '$NET' '$OUT/files.json' '$OUT/code.json' --output-file '$OUT/merged.json' > /dev/null"
cyclonedx validate --input-file "$OUT/merged.json" --input-version v1_7 | tail -1
jq 'walk(if type=="object" and .state=="null" then del(.state) else . end)' "$OUT/merged.json" > "$OUT/merged.fixed.json"
cyclonedx validate --input-file "$OUT/merged.fixed.json" --input-version v1_7 | tail -1
python3 /lab/facilitator/score.py network="$NET" theia="$OUT/files.json" cdxgen="$OUT/code.json" | tee "$OUT/score.txt"
