# BankLite Lab: Facilitator Guide

## Before the session

1. **Rehearse on the pinned image.** Run every lab end to end and check the scores:
   ```sh
   docker run --rm --network none -v "$PWD/out:/lab/out" banklite-lab ./facilitator/run-all.sh
   ```
   You should get the scores in the table under "Expected results". The run takes under a
   minute, most of it testssl.sh.
2. **Prepare USB copies** for participants whose download failed:
   ```sh
   docker save banklite-lab | gzip > banklite-lab.tar.gz      # about 450 MB
   # participant side: docker load < banklite-lab.tar.gz
   # Windows: docker save banklite-lab -o banklite-lab.tar  /  docker load -i banklite-lab.tar
   ```
3. **Keep the versions pinned.** The results depend on tool versions. A newer cdxgen may fix the
   behaviour behind A07, which changes the scores, so do not rebuild with newer tools the night
   before.

## Run sheet (60 min)

| Time | Segment | What to say or show |
|---|---|---|
| 0-7 | Why inventory first (demo) | Harvest-now, decrypt-later. India's DST roadmap puts inventory first and expects vendor CBOMs from FY 2027-28, and CERT-In v2.0 already lists CBOM minimum elements. The IIT Jammu measurement of 32,011 domains found 49.3% hybrid key exchange but 0% post-quantum certificates. Show `openssl s_client` on :8443 live. |
| 7-19 | Lab 1, network | Walk the room. Make sure pairs notice the fallback to X25519 and the `AES128-SHA` (static RSA) suite on :8444. |
| 19-34 | Lab 2, files and code | Point out early that theia does not scan source code and cdxgen does not parse certificates. Ask who found something by reading the code. |
| 34-46 | Lab 3, merge | Let the validation failure happen, because it is the lesson: tools emit invalid CBOMs too. |
| 46-56 | Lab 4, prioritise | Ask two pairs for their top five. They will disagree about X for signatures, which is a good discussion. |
| 56-60 | Answer key | Run the scorer on the projector and reveal the three assets no tool found. |

Scoring on the projector:

```sh
python3 facilitator/score.py network=out/network.json theia=out/files.json cdxgen=out/code.json
```

## Answer key

| ID | Asset | Where | Found by | Quantum view |
|---|---|---|---|---|
| A01 | TLS 1.3, payments API | :8443 | network | Key exchange already hybrid |
| A02 | ML-KEM-768 in X25519MLKEM768 | :8443, `config/tls.json`, `openssl.cnf` Groups | network only (theia ignores `Groups`) | Safe. This is the target state |
| A03 | TLS 1.2 accepting AES128-SHA (static RSA) | :8444 | network; theia partly (via openssl.cnf) | Worst case for HNDL |
| A04 | Certificate api.banklite.local, ECDSA P-256 | `certs/api.crt` and `.key` | theia; cdxgen partly (key file only) | Vulnerable, authentication only |
| A05 | Certificate legacy.banklite.local, RSA-2048 | `certs/legacy.crt` and `.key` | theia; cdxgen partly | Vulnerable, authentication only |
| A06 | Unencrypted RSA-2048 private key backup | `keys/backup_rsa.pem` | theia; cdxgen partly (calls it a certificate) | Vulnerable; delete it today |
| A07 | AES-128-ECB with hard-coded key | `src/card.js` | **none** (cdxgen detects it, then drops it) | Classical failure, not quantum |
| A08 | SHA-1 receipt IDs | `src/receipt.js` | cdxgen | Classical failure |
| A09 | HMAC-SHA256 webhooks | `src/webhook.js` | cdxgen partly (reports SHA-256) | Safe; do not migrate |
| A10 | PKCS#12 keystore, RSA-2048 signing key | `keystore/settlement.p12` | theia and cdxgen partly (opaque file) | Vulnerable; long-lived signatures |
| A11 | SHA256withRSA signing in Java | `settlement/SettlementSigner.java` | **none** (no Java source scanner in this lab) | Vulnerable |
| A12 | OpenSSL policy: TLS 1.2 minimum, AES128-SHA at SECLEVEL=1 | `config/openssl.cnf` | theia | Re-enables A03 system-wide |
| A13 | AES-256-CBC, split key, zero IV, runtime-built cipher name | `src/legacy/vault.js` | **none** (planted to beat static tools) | Classical failure |

Full match rules: `answer-key/assets.json`. Worksheet solution: `answer-key/prioritise.solution.csv`.
Its top five are A03, A10, A11, A12, and A04 or A05.

## Expected results

From `solutions/score.txt`. Y = found, ~ = right file but wrong or missing algorithm or type.

| | network (by hand) | CBOMkit-theia | cdxgen | union |
|---|---|---|---|---|
| Found (Y) | 3 | 4 | 1 | 8 |
| Partial (~) | 0 | 2 | 5 | 2 |
| Missed | 10 | 7 | 7 | 3 |

The key message: no single view finds more than 4 of 13, the union finds 8, and 3 are found by
nothing.

## Known tool behaviour (pinned versions)

All of these are reproducible on the versions in the README. Present them as facts about a
specific version, not as criticism. The projects are open source, and reporting these is how
they improve.

1. **cdxgen 12.8.5: Node.js cipher names are dropped.** Its JavaScript analyser detects
   `aes-128-ecb` in `card.js`, but the name is never mapped to its OID-table entry `aes128-ECB`,
   so the component is left out of the CBOM.
2. **cdxgen 12.8.5: wrong SHA-1 OID.** `sha-1` is given OID `2.16.840.1.113719.1.2.8.82` (a Novell
   arc) instead of `1.3.14.3.2.26`.
3. **cdxgen 12.8.5: crypto only in multi-type mode.** With `-t js --include-crypto` it emits no
   crypto components at all; leave out `-t`. Its key-file glob does not include `*.crt`, and it
   labels private keys and keystores as `certificate`.
4. **CycloneDX CLI 0.33.1: invalid merge output.** `merge` writes `"state": "null"` (and
   `"size": 0`) into `relatedCryptoMaterialProperties`, so the merged BOM fails 1.7 validation.
5. **CBOMkit-theia @445206c: partial OpenSSL config and keystore coverage.** It reports
   `MinProtocol` and `CipherString` but not `Groups`, so a configured ML-KEM group is invisible
   from files. It also reports a password-protected PKCS#12 only as `pkcs12-file`.

Both scanners emit CycloneDX 1.7 by default. The hand-written network CBOM is 1.6, and merging
works across the two versions.

## If something goes wrong

| Symptom | Fix |
|---|---|
| `check.sh`: cannot write to `/lab/out` | Linux: add `--user "$(id -u):$(id -g)"`. Windows: run from the repo folder with `-v "${PWD}/out:/lab/out"`. Or skip the mount and use `docker cp` |
| BankLite ports fail | `cat /tmp/banklite.log`, then restart the container |
| No Docker on the laptop | Pair with a neighbour; every step is on the projector |
| A pair falls behind | `cp solutions/* out/` and join at Lab 3 |

The files in `solutions/` came from one reference build. Keys and certificate serials differ in
every build, but asset names, paths and scores are the same.

## Regenerating `solutions/`

```sh
mkdir -p out && docker run --rm --network none -v "$PWD/out:/lab/out" banklite-lab ./facilitator/run-all.sh
cp out/{lab1_8443.txt,lab1_testssl_8444.txt,files.json,code.json,merged.json,merged.fixed.json,score.txt} solutions/
cp answer-key/network.solution.json solutions/network.json
```

`merged.json` is invalid on purpose: it is the raw merge output used in Lab 3.
