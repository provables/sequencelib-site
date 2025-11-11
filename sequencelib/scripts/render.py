#!/usr/bin/env python3

import os
from pathlib import Path
from jinja2 import Environment, FileSystemLoader
import networkx as nx
from collections import OrderedDict
import itertools
import re
import json
from more_itertools import stagger

HERE = Path(__file__).parent.resolve()
SEQUENCELIB_LEAN_INFO = Path(
    os.environ.get("SEQUENCELIB_LEAN_INFO", "/tmp/sequencelib_lean_info.json")
)
TEMPLATE = "seq.j2"
SUMMARY = "block.j2"
BASE_URL = os.environ.get(
    "DOCS_BASE_URL", "https://provables.github.io/sequencelib/docs"
)
OUTPUT_DIR = Path(os.environ.get("OUTPUT_DIR", "/tmp/output"))
SIDEBAR_OUTPUT = Path(os.environ.get("SIDEBAR_OUTPUT", "/tmp/info_by_block.json"))

env = Environment(loader=FileSystemLoader(HERE))
TMPL = env.get_template(TEMPLATE)
SUMMARY_TMPL = env.get_template(SUMMARY)


def all_equivalences(equivalences):
    g = nx.DiGraph()
    g.add_edges_from(equivalences)
    return nx.transitive_closure(g)


def values_table(decls):
    MAX_VALUE = 101
    data = OrderedDict()
    equivalences = OrderedDict()
    for decl, decl_info in decls.items():
        thms = decl_info["thms"]
        max_ = 0
        values = [{}] * MAX_VALUE
        for thm in thms.values():
            if thm["type"] == "equiv":
                equivalences[thm["seq1"], thm["seq2"]] = (
                    thm["theorem"],
                    decl_info["mod"],
                )
                continue
            if thm["type"] != "value":
                continue
            values[thm["index"]] = {"value": thm["value"], "thm": thm["theorem"]}
            max_ = max(max_, thm["index"])
        data[decl] = {"values": values, "max": max_}

    closure = all_equivalences(equivalences)
    for decl1, decl2 in itertools.product(closure, closure):
        print(f"processing equiv {decl1} = {decl2}")
        for idx, (value1, value2) in enumerate(
            zip(data[decl1]["values"], data[decl2]["values"])
        ):
            if "thm" in value1 and "thm" not in value2:
                data[decl2]["values"][idx] = {"value": value1["value"]}
            if "thm" not in value1 and "thm" in value2:
                data[decl1]["values"][idx] = {"value": value2["value"]}

    max_n = max([row["max"] for row in data.values()])
    # headers = ["n"] + list(range(decls["offset"], max_n + 1))
    return data, max_n, equivalences


def tag_to_block(tag):
    return tag[:4]


def simple(name):
    return name.split(".")[-1]


def name_to_mod(name):
    return f'{name.replace(".", "/")}.html'


def computability(value):
    if value:
        return ("computable", "info")
    else:
        return ("noncomputable", "warning")


def transponse_to_bytags(info):
    result = {}
    for mod, tags_in_mod in info.items():
        for tag, decls_for_tag in tags_in_mod.items():
            bymods = result.setdefault(tag, {})
            bymods.setdefault("mods", {})
            bymods["mods"][mod] = decls_for_tag
            bymods["description"] = decls_for_tag["description"]
            bymods["keywords"] = decls_for_tag["keywords"]
            bymods["offset"] = decls_for_tag["offset"]
            decl = next(iter(decls_for_tag["decls"].values()))
            bymods["codomain"] = decl["codomain"]
    return OrderedDict(sorted(result.items()))


def process_tag(tag, value, prev_tag, next_tag):
    description = value["description"]
    offset = value["offset"]
    codomain = {"Codomain.Nat": "ℕ", "Codomain.Int": "ℤ"}[value["codomain"]]
    all_decls_for_tag = {}
    for mod_name, mod in value["mods"].items():
        for decl, d in mod["decls"].items():
            d["mod"] = mod_name
            all_decls_for_tag[decl] = d
    table, max_n, equivs = values_table(all_decls_for_tag)
    value_indices = list(range(offset, max_n + 1))
    decls = {
        simple(decl): {
            "full_name": decl,
            "computability": computability(decl_data["isComputable"])[0],
            "computability_tag": computability(decl_data["isComputable"])[1],
            "values": [
                (x.get("value", ""), x.get("thm"))
                for x in table[decl]["values"][offset : max_n + 1]
            ],
            "mod": name_to_mod(decl_data["mod"]),
        }
        for (decl, decl_data) in all_decls_for_tag.items()
    }
    equivalences = [(a, b, c, name_to_mod(m)) for (a, b), (c, m) in equivs.items()]
    return {
        "base_url": BASE_URL,
        "tag": tag,
        "description": escape(description),
        "offset": offset,
        "codomain": codomain,
        "decls": decls,
        "value_indices": value_indices,
        "equivalences": equivalences,
        "prev_tag": prev_tag,
        "next_tag": next_tag,
        "mods": set(decl["mod"] for decl in decls.values()),
    }


def escape(text):
    return re.sub(r"([\*_<>{}])", r"\\\1", text)


def render(by_tags, output_dir, only_block=None):
    by_blocks = {}
    # iterate over a window -1, 0, +1 and set prev and next
    for prev, cur, next in stagger(by_tags.items(), offsets=(-1, 0, 1), longest=True):
        if cur is None:
            continue
        if prev is None:
            prev_tag = None
        else:
            (prev_tag, _) = prev
        if next is None:
            next_tag = None
        else:
            (next_tag, _) = next
        (tag, value) = cur
        block = tag_to_block(tag)
        by_blocks.setdefault(block, {})
        if only_block and block != only_block:
            continue
        by_blocks[block].setdefault("seqs", [])
        by_blocks[block]["seqs"].append(
            {"tag": tag, "description": escape(value["description"])}
        )
        print(f"Rendering: {tag}")
        data = process_tag(tag, value, prev_tag, next_tag)
        content = TMPL.render(**data)
        out_dir = output_dir / block
        out_dir.mkdir(parents=True, exist_ok=True)
        out_file = out_dir / f"{tag}.mdx"
        out_file.write_text(content)

    # iterate over a window -1, 0 and set prev to last of -1 and next to first of 0
    for prev, block in stagger(by_blocks, offsets=(-1, 0)):
        if block is None:
            continue
        by_blocks[block]["num_seqs_in_block"] = len(by_blocks[block].get("seqs", []))
        by_blocks[block].get("seqs", []).sort(key=lambda x: x["tag"])
        print(f"Rendering summary for block: {block}")
        out_dir = output_dir / block
        out_dir.mkdir(parents=True, exist_ok=True)
        out_file = out_dir / "summary.mdx"
        out_file.write_text(
            SUMMARY_TMPL.render(block=block, prev=prev, **by_blocks[block])
        )


def gen_sidebar(by_tags, output_path):
    by_blocks = {}
    print("Generating sidebar")
    for tag in by_tags:
        block = tag_to_block(tag)
        by_blocks.setdefault(block, [])
        by_blocks[block].append(tag)
    output_path.write_text(json.dumps(by_blocks))
    print("Done")


def main(info_fpath, output_path, sidebar_path):
    info = json.load(Path(info_fpath).open())
    info_by_tags = transponse_to_bytags(info)
    render(info_by_tags, output_path)
    gen_sidebar(info_by_tags, sidebar_path)


if __name__ == "__main__":
    main(SEQUENCELIB_LEAN_INFO, OUTPUT_DIR, SIDEBAR_OUTPUT)
