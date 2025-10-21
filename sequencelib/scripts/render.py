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
    return result


def process_tag(tag, value):
    description = value["description"]
    offset = value["offset"]
    codomain = value["codomain"]
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
            "mod": f'{decl_data["mod"].replace(".", "/")}.html',
        }
        for (decl, decl_data) in all_decls_for_tag.items()
    }
    return {
        "base_url": BASE_URL,
        "tag": tag,
        "description": description,
        "offset": offset,
        "codomain": codomain,
        "decls": decls,
        "value_indices": value_indices,
        "equivalences": [(a, b, c) for (a, b), c in equivs.items()],
    }


def render(tag, value):
    out = OUTPUT_DIR / f"{tag}.mdx"
    content = TMPL.render(**process_tag(tag, value))
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
