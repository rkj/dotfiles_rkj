#!/usr/bin/env python3
"""
set_coins.py — Update TotalCoins in a Vampire Crawlers save file.

The .save format is a JSON wrapper:
  { "Version": 1, "Checksum": "<base64 SHA-1>", "Data": { ... } }

The checksum is SHA-1 over the UTF-8 bytes of the standalone Data JSON
(2-space indent, CRLF line endings). Inside the wrapper the Data block
is indented by an extra 2 spaces, so we strip those before hashing.

Usage:
  python set_vampire_crawlers_coins.py <save_file> --coins <coins>
  python set_vampire_crawlers_coins.py <save_file> --fix-checksum

Example:
  python set_vampire_crawlers_coins.py SaveProfile0.save --coins 200000
  python set_vampire_crawlers_coins.py SaveProfile0.save --fix-checksum
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


def update_checksum(content: str) -> tuple[str, str]:
    """Rewrite the wrapper checksum and return the updated content/checksum."""
    new_checksum = compute_checksum(content)
    content, replacements = re.subn(
        r'("Checksum": )"[^"]*"',
        rf'\1"{new_checksum}"',
        content,
        count=1,
    )
    if replacements != 1:
        raise ValueError("Malformed save file: expected exactly one Checksum field.")

    return content, new_checksum


def set_coins(content: str, coins: int) -> str:
    """Patch TotalCoins in wrapped save content.

    Replaces every "TotalCoins" occurrence because ProfileSaveData and
    ProgressionSaveData both carry this field.

    Args:
        content: Wrapped save file content.
        coins:   New TotalCoins value to write.
    """
    original_matches = re.findall(r'"TotalCoins": \d+', content)
    if not original_matches:
        raise ValueError("No TotalCoins field found.")

    content = re.sub(r'("TotalCoins": )\d+', rf'\g<1>{coins}', content)
    print(f"Updated {len(original_matches)} TotalCoins field(s): "
          f"{original_matches[0]} → {coins}")

    return content


def patch_save(save_path: str, coins: int | None, fix_checksum: bool) -> None:
    """Modify a save file in-place according to the requested operations."""
    with open(save_path, 'r', newline='') as fh:
        content = fh.read()

    if coins is not None:
        content = set_coins(content, coins)

    if coins is not None or fix_checksum:
        content, new_checksum = update_checksum(content)
        print(f"Checksum updated: {new_checksum}")

    with open(save_path, 'w', newline='') as fh:
        fh.write(content)
    print(f"Saved: {save_path}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Patch a Vampire Crawlers .save file.",
    )
    parser.add_argument(
        'save_path',
        help="Path to the .save file (e.g. SaveProfile0.save).",
    )
    parser.add_argument(
        '--coins',
        type=int,
        help="New TotalCoins value to write (e.g. 200000).",
    )
    parser.add_argument(
        '--fix-checksum',
        action='store_true',
        help="Rewrite Checksum for the current Data block without changing coins.",
    )
    args = parser.parse_args()

    if args.coins is None and not args.fix_checksum:
        parser.error("specify --coins or --fix-checksum")

    if args.coins is not None and args.coins < 0:
        parser.error("--coins must be a non-negative integer")

    try:
        patch_save(args.save_path, args.coins, args.fix_checksum)
    except ValueError as exc:
        sys.exit(f"Error: {exc}")


if __name__ == '__main__':
    main()
