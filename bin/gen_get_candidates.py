#!/usr/bin/env python3
"""Generate GET filename candidates from upload-accepted filenames.

Why this exists:
  The filename that is accepted during upload is not always the string that must
  be requested later. For example, if the backend stores the literal string
  `shell.jpg%00.phar`, the URL path must usually request `shell.jpg%2500.phar`,
  because `%25` is the URL encoding for a literal percent sign.

  This script generates common variants: literal, URL-encoded literal,
  decoded-once, decoded-twice, sanitized-control-chars, and truncated-at-control.
"""
from urllib.parse import unquote, quote
import re
import sys

CONTROL_CHARS = ["\x00", "\n", "\r", "\t", "\x0b", "\x0c"]

def add(out, value):
    value = value.strip()
    if value:
        out.add(value)

def url_quote_path(s):
    return quote(s, safe="/._-~:")

def remove_controls(s):
    for c in CONTROL_CHARS:
        s = s.replace(c, "")
    return s

def truncate_at_controls(s):
    positions = [s.find(c) for c in CONTROL_CHARS if c in s]
    return s if not positions else s[:min(positions)]

def normalize_pathish(s):
    return {
        s.rstrip(" ."),
        s.replace("\\", ""),
        s.replace("\\", "/"),
        s.replace("/.", "."),
        s.replace("./", ""),
    }

def generate(name):
    out = set()
    original = name.strip()
    if not original:
        return out

    add(out, original)
    add(out, url_quote_path(original))

    dec1 = unquote(original)
    dec2 = unquote(dec1)

    for v in (dec1, dec2):
        add(out, url_quote_path(v))
        add(out, url_quote_path(remove_controls(v)))
        add(out, url_quote_path(truncate_at_controls(v)))
        add(out, url_quote_path(v.strip(" .\r\n\t\x00")))
        for n in normalize_pathish(v):
            add(out, url_quote_path(n))

    raw_removed = re.sub(r"%00|%0a|%0A|%0d|%0D|%09|%20", "", original)
    add(out, raw_removed)
    add(out, url_quote_path(raw_removed))

    return out

def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} accepted_filenames.txt", file=sys.stderr)
        sys.exit(1)

    all_candidates = set()
    with open(sys.argv[1], "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            all_candidates.update(generate(line))

    for candidate in sorted(all_candidates):
        print(candidate)

if __name__ == "__main__":
    main()
