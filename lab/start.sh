#!/bin/sh
# Starts BankLite in the background, then runs the given command (default: a shell).
# Any --user works: give tools a writable home (CBOMkit-theia writes its config there).
[ -w "${HOME:-/}" ] && [ "${HOME:-/}" != / ] || export HOME=/tmp/home
mkdir -p "$HOME" /lab/out 2>/dev/null
node /banklite/src/server.js > /tmp/banklite.log 2>&1 &
for i in 1 2 3 4 5 6 7 8 9 10; do
  grep -q ':8444' /tmp/banklite.log 2>/dev/null && break
  sleep 0.5
done
exec "$@"
