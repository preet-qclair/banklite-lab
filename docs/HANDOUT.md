# BankLite Lab: Participant Handout

**The challenge.** BankLite is a small payment API run by a fictional bank. Someone has to
migrate it to post-quantum cryptography, and nobody knows where its cryptography is. Work in
pairs and list every cryptographic asset you can find. Each asset counts as one point. There are
13 in total, and at least one is designed so that no tool finds it.

Start the lab shell (see the README). BankLite starts automatically inside it. Everything you
save in `out/` also appears in the `out/` folder on your laptop.

---

## Lab 1: the network view (12 min)

BankLite listens on two ports, 8443 and 8444. Find out what each one negotiates.

```sh
# Port 8443: offer the hybrid post-quantum group first
openssl s_client -connect localhost:8443 -groups X25519MLKEM768:X25519 </dev/null 2>/dev/null \
  | grep -E 'Negotiated|Cipher is|Peer signature type|subject='

# Port 8443 again, this time as an old client that only knows X25519
openssl s_client -connect localhost:8443 -groups X25519 </dev/null 2>/dev/null \
  | grep -E 'Temp Key|Cipher is'

# Port 8444: a full scan of protocols, cipher suites, key exchange and certificate
testssl --quiet --color 0 -p -P -f -S localhost:8444
```

For each port, write down the protocol version, key-exchange group, cipher suites and
certificate signature algorithm.

**Write your first CBOM.** Copy the template and replace the four `FILL_ME` values with what
you found:

```sh
cp templates/network.json out/network.json
nano out/network.json        # or vi
jq . out/network.json > /dev/null && echo "valid JSON"
```

**Think about it**
1. Which port protects recorded traffic against a future quantum computer? Why?
2. What happens on 8443 when the client does not support ML-KEM?
3. Port 8444 offers `AES128-SHA`. What key exchange does it use, and why is that the worst case
   for harvest-now, decrypt-later?

---

## Lab 2: the file and code view (15 min)

Scan BankLite with two tools. Each one writes a CBOM.

```sh
# Files: certificates, keys, keystores, OpenSSL configuration
cbomkit-theia dir /banklite > out/files.json

# Source code: crypto API calls
cdxgen --include-crypto --no-install-deps -o out/code.json /banklite
```

See what each tool found:

```sh
jq -r '.components[] | [.cryptoProperties.assetType, .name, (.evidence.occurrences // [] | map(.location) | join(","))] | @tsv' out/files.json

jq -r '.components[] | select(.type=="cryptographic-asset") | [.cryptoProperties.assetType, .name, (.properties // [] | map(select(.name=="SrcFile").value) | join(","))] | @tsv' out/code.json
```

Then read the code yourself and look for what the scanners missed:

```sh
ls -R /banklite
cat /banklite/src/*.js /banklite/src/legacy/*.js
cat /banklite/settlement/SettlementSigner.java /banklite/config/*
```

**Think about it**
1. Which assets did both tools find? Which did only one find?
2. Did anything get the wrong asset type? (Look at what cdxgen calls `backup_rsa.pem`.)
3. Find one asset in the source code that neither tool reported.

---

## Lab 3: merge, validate, compare (12 min)

Combine the three views into one CBOM and check it against the CycloneDX schema:

```sh
cyclonedx merge --input-files out/network.json out/files.json out/code.json --output-file out/merged.json
cyclonedx validate --input-file out/merged.json --input-version v1_7
```

It fails. Find out why:

```sh
grep -n '"state"' out/merged.json | head
```

The merge tool wrote a value the schema does not allow. Repair it and validate again:

```sh
jq 'walk(if type=="object" and .state=="null" then del(.state) else . end)' out/merged.json > out/merged.fixed.json
cyclonedx validate --input-file out/merged.fixed.json --input-version v1_7
```

Pick one certificate, one key and one algorithm in `out/merged.fixed.json`, and read their
`cryptoProperties`:

```sh
jq '.components[] | select(.cryptoProperties.assetType=="certificate") | .cryptoProperties' out/merged.fixed.json | head -30
```

**Think about it**
1. Do the `bom-ref` links between a certificate, its key and its algorithm survive the merge?
2. If an auditor received only the merged CBOM, which of your findings would be missing from it?

---

## Lab 4: prioritise (10 min)

```sh
cp worksheet/prioritise.xlsx out/
```

Open `out/prioritise.xlsx` on your laptop in Excel, LibreOffice or Google Sheets. For each asset,
fill in:

* **Breaks under quantum? (Y/N).** Does a quantum computer break it? Shor's algorithm breaks RSA,
  ECDSA and ECDH. Grover's algorithm only weakens AES and SHA-2.
* **X.** How many years must the data stay secret, or the signature stay valid?
* **Y.** How many years would migrating it take?
* **Exposure.** 1 = internal, 2 = partner, 3 = internet.

The sheet computes the Mosca ratio (X + Y) / Z with Z = 10 years. Above 1.0 means you are
already late. Multiplying by exposure gives a priority score.

Then:
1. Pick the **top five** to migrate first.
2. Mark every asset that needs a **classical fix today**, whatever happens with quantum.
3. Find one asset that should **not** be migrated at all.

---

## Answer key (4 min)

The facilitator reveals all 13 assets and scores everyone's CBOMs live. Count your pair's points.

If anything failed during the session, copy the reference outputs and carry on:

```sh
cp solutions/* out/
```

## Take it home

Everything here is open source. Re-run the whole lab any time with
`docker run --rm -it banklite-lab`, try it on your own code, and if you find a tool
behaving strangely, report it to the project. That is how these tools get better.
