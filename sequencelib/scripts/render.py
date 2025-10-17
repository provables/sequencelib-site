#!/usr/bin/env python3

import os
from pathlib import Path
from jinja2 import Environment, FileSystemLoader

HERE = Path(__file__).parent.resolve()
SEQUENCELIB_LEAN_INFO = Path(
    os.environ.get("SEQUENCELIB_LEAN_INFO", "/tmp/sequencelib_lean_info.json")
)
TEMPLATE = "seq.j2"
BASE_URL = "https://provables.github.io/sequencelib/docs"

# env = Environment(loader=FileSystemLoader(Path(".").resolve()))
# t = env.get_template('config.yaml')
# t.render()

# https://provables.github.io/sequencelib/docs/Sequencelib/FiniteGroups.html#Sequence.NonIsoSubgroupsSymmOfOrder
# https://provables.github.io/sequencelib/docs/Sequencelib/FiniteGroups.html#Sequence.NonIsoSubgroupsSymmOfOrder_one
# https://provables.github.io/sequencelib/docs/Sequencelib/FiniteGroups.html#Sequence.NonIsoGrpOfOrder_eq_NonIsoSubgroupsSymmOfOrder


def render():
    env = Environment(loader=FileSystemLoader(HERE))
    tmpl = env.get_template(TEMPLATE)
    computability = "noncomputable"
    computability_tag = "warning"
    return tmpl.render(
        base_url=BASE_URL,
        tag="A000001",
        module_html="Sequencelib/FiniteGroups.html",
        description="Number of groups of order n.",
        offset=0,
        codomain="ℕ",
        decls=[
            ("NonIsoSubgroupsSymmOfOrder", "Sequence.NonIsoSubgroupsSymmOfOrder"),
            ("NonIsoGrpOfOrder", "Sequence.NonIsoGrpOfOrder"),
        ],
        computability=computability,
        computability_tag=computability_tag,
        value_indices=[0, 1, 2],
        values={
            "NonIsoSubgroupsSymmOfOrder": [
                (1, "Sequence.NonIsoSubgroupsSymmOfOrder_one"),
                (1, None),
                (2, None),
            ],
            "NonIsoGrpOfOrder": [
                (1, None),
                (1, None),
                (2, "Sequence.NonIsoSubgroupsSymmOfOrder_two"),
            ],
        },
        equivalences=[
            (
                "NonIsoGrpOfOrder",
                "NonIsoSubgroupsSymmOfOrder",
                "Sequence.NonIsoGrpOfOrder_eq_NonIsoSubgroupsSymmOfOrder",
            )
        ],
    )
