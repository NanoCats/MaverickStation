#!/usr/bin/env python3
"""Operation Angle Grinder: keep cut features out of the build.

Reads maverick/angle_grinder.txt (one file glob per line, # for comments) and removes
every matching #include line from tgstation.dme. Run it after an upstream sync, then
compile. The include checker (tools/ticked_file_enforcement) reads the same list, so CI
fails if a cut file sneaks back in, and does not complain that cut files are missing.

Usage: python3 tools/maverick/angle_grinder.py [--check]
"""
import fnmatch
import re
import sys

LIST = "maverick/angle_grinder.txt"
DME = "tgstation.dme"


def load_globs():
    with open(LIST, "r") as list_file:
        return [line.strip() for line in list_file if line.strip() and not line.strip().startswith("#")]


def main():
    check_only = "--check" in sys.argv
    globs = load_globs()
    with open(DME, "r", newline="") as dme_file:
        text = dme_file.read()
    newline = "\r\n" if "\r\n" in text else "\n"
    kept, cut = [], []
    for line in text.split(newline):
        match = re.match(r'#include "(.+)"', line)
        if match and any(fnmatch.fnmatch(match.group(1).replace("\\", "/"), glob) for glob in globs):
            cut.append(match.group(1))
            continue
        kept.append(line)
    for path in cut:
        print(("Would cut " if check_only else "Cut ") + path)
    if check_only:
        return 1 if cut else 0
    if cut:
        with open(DME, "w", newline="") as dme_file:
            dme_file.write(newline.join(kept))
    print(f"{len(cut)} include(s) cut.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
