#!/bin/sh
# Self-check: confirms BankLite is up and every lab tool runs. Prints ALL OK on success.
fail=0
ok()  { printf '  [ok]   %s\n' "$1"; }
bad() { printf '  [FAIL] %s\n' "$1"; fail=1; }

echo "BankLite lab self-check"

openssl version | grep -q '^OpenSSL 3\.[5-9]' && ok "$(openssl version | cut -d' ' -f1-2)" || bad "OpenSSL 3.5+ not found"

openssl s_client -connect localhost:8443 -groups X25519MLKEM768 </dev/null 2>/dev/null \
  | grep -q 'Negotiated TLS1.3 group: X25519MLKEM768' && ok "BankLite :8443 negotiates X25519MLKEM768" || bad "BankLite :8443"

openssl s_client -connect localhost:8444 -tls1_2 </dev/null 2>/dev/null \
  | grep -q 'Protocol: TLSv1.2' && ok "BankLite :8444 speaks TLS 1.2" || bad "BankLite :8444"

testssl --version 2>/dev/null | grep -q 'version' && ok "testssl.sh present" || bad "testssl.sh"

tmp=$(mktemp -d)
cbomkit-theia dir /banklite >"$tmp/f.json" 2>/dev/null \
  && [ "$(jq '.components|length' "$tmp/f.json")" -gt 0 ] && ok "cbomkit-theia produces a CBOM" || bad "cbomkit-theia"

cp -r /banklite "$tmp/src"
(cd "$tmp/src" && cdxgen --include-crypto --no-install-deps -o "$tmp/c.json" . >/dev/null 2>&1)
[ -s "$tmp/c.json" ] && [ "$(jq '[.components[]?|select(.type=="cryptographic-asset")]|length' "$tmp/c.json")" -gt 0 ] \
  && ok "cdxgen produces crypto components" || bad "cdxgen"

cyclonedx --version >/dev/null 2>&1 && ok "cyclonedx-cli present" || bad "cyclonedx-cli"
python3 /lab/facilitator/score.py t="$tmp/f.json" >/dev/null 2>&1 && ok "scorer runs" || bad "scorer"
rm -rf "$tmp"

touch /lab/out/.write-test 2>/dev/null && rm -f /lab/out/.write-test && ok "out/ folder is writable" \
  || bad "cannot write to /lab/out (on Linux, add --user \"\$(id -u):\$(id -g)\" to docker run)"

strip() { sed 's/\x1b\[[0-9;]*m//g'; }
echo "Versions: OpenSSL $(openssl version | cut -d' ' -f2), testssl $(testssl --version 2>/dev/null | strip | grep -o 'version [0-9.]*' | head -1 | cut -d' ' -f2), cdxgen $(cdxgen --version 2>/dev/null | strip | grep -o '[0-9][0-9.]*' | head -1), cyclonedx-cli $(cyclonedx --version 2>/dev/null | cut -d+ -f1)"
[ $fail -eq 0 ] && echo "ALL OK" || { echo "Some checks failed. See README, section Troubleshooting."; exit 1; }
