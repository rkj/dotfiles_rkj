#!/usr/bin/env python3
"""
set_coins.py — Update TotalCoins in a Vampire Crawlers save file.

The .save format is a JSON wrapper:
  { "Version": 1, "Checksum": "<base64 SHA-1>", "Data": { ... } }

The checksum is SHA-1 over the UTF-8 bytes of the standalone Data JSON
(2-space indent, CRLF line endings). Inside the wrapper the Data block
is indented by an extra 2 spaces, so we strip those before hashing.

Usage:
  python set_coins.py <save_file> <coins>

Example:
  python set_coins.py SaveProfile0.save 200000
"""

import argparse
import base64
import hashlib
import re
import sys


def compute_checksum(wrapped_content: str) -> str:
    """Return the Base64-encoded SHA-1 checksum expected by the game.

    Extracts the raw Data JSON block from the wrapped save content,
    removes the 2-space wrapper indentation, normalises line endings
    to CRLF, then hashes with SHA-1.
    """
    # Locate the opening brace of the Data value.
    data_start = wrapped_content.index('"Data": {') + len('"Data": ')
    data_raw = wrapped_content[data_start:]

    # Walk forward to find the matching closing brace.
    depth = 0
    for i, ch in enumerate(data_raw):
        if ch == '{':
            depth += 1
        elif ch == '}':
            depth -= 1
            if depth == 0:
                data_block = data_raw[:i + 1]
                break
    else:
        raise ValueError("Malformed save file: unmatched braces in Data block.")

    # Strip the 2-space wrapper indentation added when the Data object is
    # embedded in the outer JSON envelope.
    lines = data_block.replace('\r\n', '\n').split('\n')
    dedented = '\n'.join(line[2:] if line.startswith('  ') else line for line in lines)

    # The game hashes the standalone Data string with CRLF line endings.
    canonical = dedented.replace('\n', '\r\n')
    digest = hashlib.sha1(canonical.encode('utf-8')).digest()
    return base64.b64encode(digest).decode()


def set_coins(save_path: str, coins: int) -> None:
    """Patch TotalCoins in a save file and rewrite a valid checksum.

    Modifies the file in-place. The original file is not backed up here;
    the game already maintains its own .bak files.

    Args:
        save_path: Path to the .save file (e.g. SaveProfile0.save).
        coins:     New TotalCoins value to write.
    """
    with open(save_path, 'r', newline='') as fh:
        content = fh.read()

    # Replace every "TotalCoins" occurrence (ProfileSaveData and
    # ProgressionSaveData both carry this field).
    original_matches = re.findall(r'"TotalCoins": \d+', content)
    if not original_matches:
        sys.exit(f"Error: no TotalCoins field found in {save_path!r}.")

    content = re.sub(r'("TotalCoins": )\d+', rf'\g<1>{coins}', content)
    print(f"Updated {len(original_matches)} TotalCoins field(s): "
          f"{original_matches[0]} → {coins}")

    # Recompute and patch the checksum.
    new_checksum = compute_checksum(content)
    content = re.sub(r'("Checksum": )"[^"]*"', rf'\1"{new_checksum}"', content)
    print(f"Checksum updated: {new_checksum}")

    with open(save_path, 'w', newline='') as fh:
        fh.write(content)
    print(f"Saved: {save_path}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Set TotalCoins in a Vampire Crawlers .save file.",
    )
    parser.add_argument(
        'save_path',
        help="Path to the .save file (e.g. SaveProfile0.save).",
    )
    parser.add_argument(
        'coins',
        type=int,
        help="New coin total to write (e.g. 200000).",
    )
    args = parser.parse_args()

    if args.coins < 0:
        sys.exit("Error: coins must be a non-negative integer.")

    set_coins(args.save_path, args.coins)


if __name__ == '__main__':
    main()
