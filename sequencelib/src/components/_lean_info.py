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


# data = json.load(sys.stdin)
result = {
    "python": sys.executable,
    "ids": list_of_ids(),
}
print(json.dumps(result))
