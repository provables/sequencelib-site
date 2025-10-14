#!/usr/bin/env python

import sys, json, os
from functools import cache
from pathlib import Path
from itertools import chain

SEQUENCELIB_LEAN_INFO = Path(
    os.environ.get("SEQUENCELIB_LEAN_INFO", "/tmp/sequencelib-lean-info.json")
)

LEAN_INFO = json.load(open(SEQUENCELIB_LEAN_INFO))


def list_of_ids():
    return [int(v[1:]) for v in chain(*(x.keys() for x in LEAN_INFO.values()))]

def list_of_theorems():
    for mod, tags in LEAN_INFO.items():
        for tag, seq in tags.items():
            for decl, thms in seq["decls"].items():
                yield from thms.get("thms", [])

# data = json.load(sys.stdin)
ids = list_of_ids()
result = {
    "python": sys.executable,
    "ids": ids,
    "num_seqs": len(ids),
    "num_thms": len(list(list_of_theorems()))
}
print(json.dumps(result))
