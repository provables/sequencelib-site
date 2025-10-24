#!/usr/bin/env python3

import os
import shutil
from pathlib import Path

import render

HERE = Path(__file__).parent.resolve()
SEQUENCELIB_LEAN_INFO = Path(
    os.environ.get("SEQUENCELIB_LEAN_INFO", "/tmp/sequencelib_lean_info.json")
)
OUTPUT_DIR = Path(os.environ.get("OUTPUT_DIR", "/tmp/output"))
SIDEBAR_OUTPUT = Path(os.environ.get("SIDEBAR_OUTPUT", "/tmp/info_by_block.json"))


def build(
    info_fpath, dest, tmp_dest, output_dir=OUTPUT_DIR, sidebar_output=SIDEBAR_OUTPUT
):
    sequences = (HERE / "../src/content/docs/sequences").resolve()
    render.main(info_fpath, output_dir, sidebar_output)
    for block in os.listdir(OUTPUT_DIR):
        block_path = OUTPUT_DIR / block
        shutil.rmtree(sequences)
        sequences.mkdir()
        print(f"will move {block_path} to {sequences}")
        
