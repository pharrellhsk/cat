#!/usr/bin/env python3
"""Pack designer Excel tables under assets/config into JSON for Godot."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

HEADER_ROWS = 3
REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SRC = REPO_ROOT / "assets" / "config"
DEFAULT_OUT = REPO_ROOT / "assets" / "config" / "packed"


def _fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def _coerce(value, type_name: str):
    type_name = (type_name or "string").strip().lower()
    if value is None or value == "":
        if type_name in ("int", "integer"):
            return 0
        if type_name in ("float", "number", "double"):
            return 0.0
        if type_name in ("bool", "boolean"):
            return False
        return ""
    if type_name in ("int", "integer"):
        return int(float(value))
    if type_name in ("float", "number", "double"):
        return float(value)
    if type_name in ("bool", "boolean"):
        if isinstance(value, bool):
            return value
        text = str(value).strip().lower()
        return text in ("1", "true", "yes", "y")
    if isinstance(value, float) and value.is_integer():
        return str(int(value))
    return str(value)


def _read_sheet_rows(path: Path) -> list[list]:
    suffix = path.suffix.lower()
    if suffix == ".xls":
        try:
            import xlrd
        except ImportError:
            _fail("reading .xls requires xlrd==1.2.0 (pip install -r tools/requirements.txt)")
        book = xlrd.open_workbook(str(path))
        sheet = book.sheet_by_index(0)
        return [
            [sheet.cell_value(r, c) for c in range(sheet.ncols)]
            for r in range(sheet.nrows)
        ]
    if suffix == ".xlsx":
        try:
            import openpyxl
        except ImportError:
            _fail("reading .xlsx requires openpyxl (pip install -r tools/requirements.txt)")
        book = openpyxl.load_workbook(str(path), data_only=True, read_only=True)
        sheet = book.worksheets[0]
        rows = [list(row) for row in sheet.iter_rows(values_only=True)]
        book.close()
        return rows
    _fail(f"unsupported table format: {path.name}")


def _output_stem(path: Path) -> str:
    name = path.stem
    if "_" in name:
        return name.split("_", 1)[0]
    return name


def pack_table(path: Path) -> dict:
    rows = _read_sheet_rows(path)
    if len(rows) < HEADER_ROWS:
        _fail(f"{path.name}: expected 3 header rows, got {len(rows)}")

    names = [str(cell).strip() if cell is not None else "" for cell in rows[0]]
    types = [str(cell).strip() if cell is not None else "string" for cell in rows[1]]
    try:
        name_idx = names.index("name")
        value_idx = names.index("parameter")
    except ValueError:
        _fail(f"{path.name}: first row must include 'name' and 'parameter' columns")

    packed: dict = {}
    for row in rows[HEADER_ROWS:]:
        if row is None or all(cell is None or cell == "" for cell in row):
            continue
        key = str(row[name_idx]).strip() if name_idx < len(row) and row[name_idx] is not None else ""
        if not key:
            continue
        raw = row[value_idx] if value_idx < len(row) else None
        value_type = types[value_idx] if value_idx < len(types) else "string"
        packed[key] = _coerce(raw, value_type)
    return packed


def pack_dir(src_dir: Path, out_dir: Path) -> list[Path]:
    tables = sorted(
        [p for p in src_dir.iterdir() if p.is_file() and p.suffix.lower() in (".xls", ".xlsx")]
    )
    if not tables:
        _fail(f"no .xls/.xlsx files in {src_dir}")

    out_dir.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []
    for table in tables:
        data = pack_table(table)
        out_path = out_dir / f"{_output_stem(table)}.json"
        out_path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        written.append(out_path)
        print(f"packed {table.name} -> {out_path.relative_to(REPO_ROOT)} ({len(data)} keys)")
    return written


def main() -> None:
    parser = argparse.ArgumentParser(description="Pack Excel config tables into JSON")
    parser.add_argument("--src", type=Path, default=DEFAULT_SRC, help="Excel source directory")
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT, help="JSON output directory")
    args = parser.parse_args()
    pack_dir(args.src.resolve(), args.out.resolve())


if __name__ == "__main__":
    main()
