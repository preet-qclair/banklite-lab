# BankLite Lab

**Where is our cryptography? Hands-on cryptographic discovery and CBOM generation for
post-quantum migration.**

Every post-quantum migration starts with an inventory, because you cannot replace cryptography
you cannot find. BankLite is a small synthetic payment system with 13 cryptographic assets
hidden in its network endpoints, files, configuration and code. In one hour you find them with
free open-source tools, record them as a CycloneDX CBOM (Cryptographic Bill of Materials),
compare what each tool sees and misses, and rank the findings for migration.

Everything runs offline in one container. BankLite is entirely synthetic: its keys protect
nothing, and it uses no real company's systems or data.

## What you will learn

* Why cryptographic inventory comes first in post-quantum migration.
* How to discover cryptography from three views: the network, the file system and the source code.
* How to read and write a CycloneDX CBOM.
* Why no single discovery tool is enough, shown with numbers rather than claims.
* How to rank quantum-vulnerable assets with a Mosca-style rule, and how to tell quantum
  problems from classical ones.

## Quick start

You need Docker: Docker Desktop on macOS or Windows (WSL2 backend), or Docker Engine on Linux.
You also need about 3 GB of free disk space and 4 GB of RAM.

```sh
git clone https://github.com/preet-qclair/banklite-lab.git
cd banklite-lab
docker build -t banklite-lab .
mkdir -p out
docker run --rm -it --user "$(id -u):$(id -g)" -v "$PWD/out:/lab/out" banklite-lab ./check.sh
```

On Windows PowerShell, leave out `--user ...` and use `-v "${PWD}/out:/lab/out"`.

The check should end with `ALL OK`. The build needs internet once (a few minutes). After that,
nothing needs a network connection.

To start the lab shell, run the same command without `./check.sh`:

```sh
docker run --rm -it --user "$(id -u):$(id -g)" -v "$PWD/out:/lab/out" banklite-lab
```

Then follow **[docs/HANDOUT.md](docs/HANDOUT.md)**. Facilitators should read
**[docs/FACILITATOR.md](docs/FACILITATOR.md)**.

## The tools

All of these are free and open source. This lab exists to show what they can do today, and
where the community can still improve them.

| Tool | Version | Project | What it does here |
|---|---|---|---|
| OpenSSL | 3.5.7 | [openssl.org](https://www.openssl.org) | Probes TLS endpoints, including the hybrid ML-KEM group |
| testssl.sh | 3.2.1 | [testssl.sh](https://testssl.sh) | Lists protocols, cipher suites, KEMs and certificates |
| CBOMkit-theia | `445206c` | [PQCA / cbomkit](https://github.com/cbomkit/cbomkit-theia) | Finds certificates, keys, keystores and OpenSSL configuration in files |
| cdxgen | 12.8.5 | [OWASP CycloneDX](https://github.com/CycloneDX/cdxgen) | Finds crypto API calls in JavaScript source |
| CycloneDX CLI | 0.33.1 | [CycloneDX](https://github.com/CycloneDX/cyclonedx-cli) | Merges and validates CBOMs |
| jq | 1.7 | [jqlang.org](https://jqlang.org) | Queries and repairs CBOM JSON |

The CBOM format is [CycloneDX](https://cyclonedx.org/capabilities/cbom/) 1.6/1.7, standardised
as ECMA-424.

## Repository layout

```
banklite/       the target system: Node.js payment API, Java settlement signer, configs.
                Keys and certificates are generated when the image is built.
lab/            check.sh, start.sh, templates/network.json (the CBOM you fill in)
worksheet/      prioritisation worksheet (xlsx with formulas, plus a plain csv)
docs/           HANDOUT.md (participants), FACILITATOR.md (running the session)
facilitator/    score.py (scores CBOMs against the answer key), run-all.sh (rehearsal)
answer-key/     the 13 planted assets, the solution CBOM and the worksheet solution. Try not to peek
solutions/      pre-generated output of every lab step, as a fallback
```

## Licence

Apache-2.0 (see [LICENSE](LICENSE)). Each tool keeps its own licence.
