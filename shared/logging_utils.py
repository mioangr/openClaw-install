#!/usr/bin/env python3
"""Shared logging helpers and paths."""

import logging
import os
from pathlib import Path

from shared.config import ROOT_DIR


APP_LOG_FILE = Path(os.getenv("APP_LOG_FILE", str(ROOT_DIR / "logs" / "activity.log")))


def ensure_log_dir() -> None:
    APP_LOG_FILE.parent.mkdir(parents=True, exist_ok=True)


def configure_file_logger(name: str) -> logging.Logger:
    ensure_log_dir()
    logger = logging.getLogger(name)
    logger.setLevel(logging.INFO)

    if not any(
        isinstance(handler, logging.FileHandler) and Path(handler.baseFilename) == APP_LOG_FILE
        for handler in logger.handlers
    ):
        handler = logging.FileHandler(APP_LOG_FILE)
        handler.setFormatter(
            logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
        )
        logger.addHandler(handler)

    return logger
