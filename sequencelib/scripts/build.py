#!/usr/bin/env python3

import os
import shutil
import subprocess
import tempfile
from itertools import islice
from pathlib import Path

import render

HERE = Path(__file__).parent.resolve()
SEQUENCELIB_LEAN_INFO = Path(
    os.environ.get("SEQUENCELIB_LEAN_INFO", "/tmp/sequencelib_lean_info.json")
)
OUTPUT_DIR = Path(os.environ.get("OUTPUT_DIR", "/tmp/output"))
SIDEBAR_OUTPUT = Path(os.environ.get("SIDEBAR_OUTPUT", "/tmp/info_by_block.json"))
DIST = Path(os.environ.get("DIST", "/tmp/dist"))
_LIMIT = os.environ.get("_LIMIT")


def npx_build(dest):
    subprocess.run(
        ["npx", "astro", "build", "--outDir", dest], check=True, cwd=HERE / ".."
    )


def gen_index(dest):
    subprocess.run(["npx", "pagefind", "--site", dest], check=True, cwd=HERE / "..")


def build_for_block(block, dest, tmp_dest, output_dir=OUTPUT_DIR):
    sequences = (HERE / "../src/content/docs/sequences").resolve()
    shutil.rmtree(sequences)
    sequences.mkdir()
    block_path = output_dir / block
    block_path.rename(sequences / block)
    npx_build(tmp_dest)
    out = tmp_dest / block
    out.rename(dest / block)


def build(
    info_fpath,
    dest,
    tmp_dest,
    output_dir=OUTPUT_DIR,
    sidebar_output=SIDEBAR_OUTPUT,
    limit=_LIMIT,
):
    render.main(info_fpath, output_dir, sidebar_output)
    print("============================")
    print(f"Building initial empty site")
    print("============================")
    npx_build(dest)
    it = (
        islice(os.listdir(output_dir), int(limit))
        if limit is not None
        else os.listdir(output_dir)
    )
    for block in it:
        print("========================")
        print(f"Building block {block}")
        print("========================")
        build_for_block(block, dest, tmp_dest, output_dir)
    print("=========")
    print(f"Indexing")
    print("=========")
    gen_index(dest)


if __name__ == "__main__":
    temp = Path(tempfile.mkdtemp())
    build(SEQUENCELIB_LEAN_INFO, DIST, temp, OUTPUT_DIR, SIDEBAR_OUTPUT, _LIMIT)
