#!/usr/bin/env python3
"""Helpers for talking to the local Ollama service."""

from __future__ import annotations

import os
from typing import Any, Dict, List

import requests


OLLAMA_URL = os.getenv("OLLAMA_URL", "http://ollama:11434")
REQUEST_TIMEOUT_SECONDS = 120


def list_installed_models() -> List[Dict[str, Any]]:
    response = requests.get(
        f"{OLLAMA_URL}/api/tags",
        timeout=REQUEST_TIMEOUT_SECONDS,
    )
    response.raise_for_status()
    payload = response.json()
    return payload.get("models", [])


def list_installed_model_names() -> List[str]:
    return [model.get("name", "") for model in list_installed_models() if model.get("name")]


def chat_with_model(model: str, messages: List[Dict[str, str]]) -> Dict[str, Any]:
    response = requests.post(
        f"{OLLAMA_URL}/api/chat",
        json={
            "model": model,
            "messages": messages,
            "stream": False,
        },
        timeout=REQUEST_TIMEOUT_SECONDS,
    )
    response.raise_for_status()
    return response.json()
