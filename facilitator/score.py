#!/usr/bin/env python3
"""Score one or more CBOMs against the BankLite answer key.

Usage: score.py [--key answer-key/assets.json] LABEL=cbom.json [LABEL=cbom.json ...]

Prints, for every planted asset, whether each CBOM found it fully (Y),
partially (~: right place but wrong or missing algorithm/type) or not at all (-).
"""
import json
import re
import sys
from pathlib import Path


def component_facts(c):
    cp = c.get("cryptoProperties", {})
    locs = [o.get("location", "") for o in (c.get("evidence", {}).get("occurrences") or [])]
    props = c.get("properties") or []
    for p in props:
        if p.get("name") in ("SrcFile", "cdx:crypto:sourceLocation"):
            locs.append(p.get("value", "").split(":")[0] if "sourceLocation" in p["name"] else p.get("value", ""))
    return {
        "name": c.get("name", ""),
        "type": cp.get("assetType", ""),
        "locs": locs,
        "props": " ".join(str(p.get("value", "")) for p in props) + " " + json.dumps(cp),
    }


def rule_hits(rule, f):
    if "loc" in rule and not any(re.search(rule["loc"], l) for l in f["locs"]):
        return False
    if "type" in rule and f["type"] != rule["type"]:
        return False
    if "name" in rule and not re.search(rule["name"], f["name"]):
        return False
    if "prop" in rule and not re.search(rule["prop"], f["props"]):
        return False
    return True


def grade(asset, facts):
    m = asset["match"]
    if any(rule_hits(r, f) for r in m.get("full", []) for f in facts):
        return "Y"
    if any(rule_hits(r, f) for r in m.get("partial", []) for f in facts):
        return "~"
    return "-"


def main(argv):
    key = Path(__file__).resolve().parent.parent / "answer-key" / "assets.json"
    if not key.exists():
        key = Path("/lab/answer-key/assets.json")
    if argv[:1] == ["--key"]:
        key, argv = Path(argv[1]), argv[2:]
    if not argv:
        sys.exit(__doc__)
    assets = json.loads(key.read_text())["assets"]
    boms = []
    for arg in argv:
        label, _, path = arg.partition("=")
        comps = json.loads(Path(path).read_text()).get("components") or []
        boms.append((label, [component_facts(c) for c in comps]))

    width = max(len(l) for l, _ in boms + [("union", [])])
    print("asset " + " ".join(l.rjust(width) for l, _ in boms) + "  " + "union".rjust(width) + "  what")
    totals = {l: [0, 0] for l, _ in boms + [("union", [])]}
    for a in assets:
        row = [grade(a, facts) for _, facts in boms]
        union = "Y" if "Y" in row else ("~" if "~" in row else "-")
        for (l, _), g in zip(boms + [("union", [])], row + [union]):
            totals[l][0] += g == "Y"
            totals[l][1] += g == "~"
        print(f"{a['id']:5} " + " ".join(g.rjust(width) for g in row) + "  " + union.rjust(width) + "  " + a["what"][:70])
    print()
    for l, (full, part) in totals.items():
        print(f"{l:>{width}}: {full}/{len(assets)} found, {part} partial, {len(assets) - full - part} missed")


if __name__ == "__main__":
    main(sys.argv[1:])
