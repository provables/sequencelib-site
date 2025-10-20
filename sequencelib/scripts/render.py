#!/usr/bin/env python3

import os
from pathlib import Path
from jinja2 import Environment, FileSystemLoader
import networkx as nx
from collections import OrderedDict
import itertools

HERE = Path(__file__).parent.resolve()
SEQUENCELIB_LEAN_INFO = Path(
    os.environ.get("SEQUENCELIB_LEAN_INFO", "/tmp/sequencelib_lean_info.json")
)
TEMPLATE = "seq.j2"
BASE_URL = "https://provables.github.io/sequencelib/docs"
OUTPUT_DIR = Path("/tmp")

TMPL = Environment(loader=FileSystemLoader(HERE)).get_template(TEMPLATE)


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
                equivalences[thm["seq1"], thm["seq2"]] = thm["theorem"]
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


def simple(name):
    return name.split(".")[-1]


def computability(value):
    if value:
        return ("computable", "info")
    else:
        return ("noncomputable", "warning")


def process_mod(key, value):
    """Process an entry of the JSON info."""
    for tag, data in value.items():
        module_html = f"{key.replace('.', '/')}.html"
        description = data["description"]
        offset = data["offset"]
        codomain = {"Codomain.Nat": "ℕ", "Codomain.Int": "ℤ"}[data["codomain"]]
        table, max_n, equivs = values_table(data["decls"])
        decls = {
            simple(decl): {
                "full_name": decl,
                "computability": computability(decl_data["isComputable"])[0],
                "computability_tag": computability(decl_data["isComputable"])[1],
                "values": [
                    (x.get("value", ""), x.get("thm"))
                    for x in table[decl]["values"][offset : max_n + 1]
                ],
            }
            for (decl, decl_data) in data["decls"].items()
        }
        value_indices = list(range(offset, max_n + 1))
        yield {
            "base_url": BASE_URL,
            "tag": tag,
            "module_html": module_html,
            "description": description,
            "offset": offset,
            "codomain": codomain,
            "decls": decls,
            "value_indices": value_indices,
            "equivalences": [(a, b, c) for (a, b), c in equivs.items()],
        }


def render(seq_data):
    out = OUTPUT_DIR / f"{seq_data["tag"]}.mdx"
    content = TMPL.render(**seq_data)
    out.write_text(content)

    #     base_url=BASE_URL,
    #     tag="A000001",
    #     module_html="Sequencelib/FiniteGroups.html",
    #     description="Number of groups of order n.",
    #     offset=0,
    #     codomain="ℕ",
    #     decls={
    #         "NonIsoSubgroupsSymmOfOrder": {
    #             "full_name": "Sequence.NonIsoSubgroupsSymmOfOrder",
    #             "values": [
    #                 (1, "Sequence.NonIsoSubgroupsSymmOfOrder_one"),
    #                 (1, None),
    #                 (2, None),
    #             ],
    #             "computability": "noncomputable",
    #             "computability_tag": "warning",
    #         },
    #         "NonIsoGrpOfOrder": {
    #             "full_name": "Sequence.NonIsoGrpOfOrder",
    #             "values": [
    #                 (1, None),
    #                 (1, None),
    #                 (2, "Sequence.NonIsoSubgroupsSymmOfOrder_two"),
    #             ],
    #             "computability": "noncomputable",
    #             "computability_tag": "warning",
    #         },
    #     },
    #     value_indices=[0, 1, 2],
    #     equivalences=[
    #         (
    #             "NonIsoGrpOfOrder",
    #             "NonIsoSubgroupsSymmOfOrder",
    #             "Sequence.NonIsoGrpOfOrder_eq_NonIsoSubgroupsSymmOfOrder",
    #         )
    #     ],
    # )
