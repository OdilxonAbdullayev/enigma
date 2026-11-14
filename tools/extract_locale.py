#!/usr/bin/env python3
"""Refresh Uzbek source-message catalog without rewriting game source.

Add data/localization/en.json (or another locale) with the same message keys and
translated values. Keep {named} parameters and % format tokens intact.
Only the Uzbek base catalog is regenerated; translated catalogs are preserved.
"""
from pathlib import Path
import ast
import json
import re

ROOT = Path(__file__).resolve().parents[1]
QUOTED = re.compile(r'"(?:\\.|[^"\\])*"')
FIELDS = {"name", "description", "title", "text", "body", "message", "explicit_solution", "location", "ending"}


def player_text(value):
    return (isinstance(value, str) and len(value) > 2
            and not value.startswith(("res://", "user://", "/tmp/", "http"))
            and (value[0].isupper() or any(c.isspace() for c in value) or any(ord(c) > 127 for c in value)))


def collect_json(value, output, field=""):
    if isinstance(value, dict):
        for key, item in value.items():
            collect_json(item, output, key)
    elif isinstance(value, list):
        for item in value:
            collect_json(item, output, field)
    elif field in FIELDS | {"hints"} and player_text(value):
        output.add(value)


def main():
    strings = set()
    for source in sorted((ROOT / "scripts").rglob("*.gd")):
        if "localization" in source.parts:
            continue
        for quoted in QUOTED.findall(source.read_text()):
            try:
                value = ast.literal_eval(quoted)
            except (SyntaxError, ValueError):
                continue
            if player_text(value):
                strings.add(value)
    for source in sorted((ROOT / "data").glob("*.json")):
        collect_json(json.loads(source.read_text()), strings)
    destination = ROOT / "data/localization/uz.json"
    destination.parent.mkdir(parents=True, exist_ok=True)
    document = {"locale": "uz", "source_locale": "uz", "messages": {text: text for text in sorted(strings)}}
    destination.write_text(json.dumps(document, ensure_ascii=False, indent=2) + "\n")
    print(f"Updated {destination.relative_to(ROOT)}: {len(strings)} source messages")


if __name__ == "__main__":
    main()
