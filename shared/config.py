#!/usr/bin/env python3
"""Shared configuration helpers."""

from pathlib import Path
from typing import Dict


ROOT_DIR = Path(__file__).resolve().parent.parent


def load_install_config() -> Dict[str, str]:
    values: Dict[str, str] = {}
    config_path = ROOT_DIR / "install.conf"

    if not config_path.exists():
        return values

    for raw_line in config_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue

        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip("'\"")

    return values
