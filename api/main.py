#!/usr/bin/env python3
"""FastAPI gateway for the local AI agent."""

import os
import sys
from pathlib import Path
from typing import List, Optional

from fastapi import FastAPI, Form, HTTPException, Request
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel, Field

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from api.services.redis_client import get_redis_client
from api.services.repositories import get_all_projects, get_project_map
from api.services.tasks import create_and_submit_task, get_recent_tasks, get_task_by_id
from shared.logging_utils import APP_LOG_FILE, configure_file_logger, ensure_log_dir


APP_TITLE = "Local AI Agent Gateway"
APP_VERSION = "0.1.0"
AUTH_MODE = os.getenv("AUTH_MODE", "anonymous")

app = FastAPI(title=APP_TITLE, version=APP_VERSION)
templates = Jinja2Templates(directory=str(Path(__file__).resolve().parent.parent / "www"))
static_dir = Path(__file__).resolve().parent / "static"
app_logger = configure_file_logger("api-gateway")

if static_dir.exists():
    app.mount("/static", StaticFiles(directory=str(static_dir)), name="static")


class TaskCreateRequest(BaseModel):
    project: str = Field(..., min_length=1)
    instruction: str = Field(..., min_length=1)
    model: Optional[str] = None


class TaskResponse(BaseModel):
    task_id: str
    project: str
    instruction: str
    model: str
    status: str
    created_at: str
    updated_at: str
    pr_url: str
    error: str
    success: Optional[bool] = None
    submitted_by: str


class HealthResponse(BaseModel):
    status: str
    auth_mode: str


def read_log_text(max_lines: int = 1000) -> tuple[str, int]:
    ensure_log_dir()
    if not APP_LOG_FILE.exists():
        return "No log entries yet.", 0

    log_text = APP_LOG_FILE.read_text(encoding="utf-8", errors="replace")
    lines = log_text.splitlines()
    if len(lines) > max_lines:
        lines = lines[-max_lines:]
    return "\n".join(lines) if lines else "No log entries yet.", len(lines)


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    redis_client = get_redis_client()
    try:
        redis_client.ping()
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"Redis unavailable: {exc}") from exc
    return HealthResponse(status="ok", auth_mode=AUTH_MODE)


@app.get("/api/projects")
def list_projects():
    return {"projects": get_all_projects(), "auth_mode": AUTH_MODE}


@app.get("/api/tasks", response_model=List[TaskResponse])
def list_task_records(limit: int = 20):
    return [TaskResponse(**task) for task in get_recent_tasks(limit)]


@app.get("/api/tasks/{task_id}", response_model=TaskResponse)
def get_task_record(task_id: str):
    task = get_task_by_id(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return TaskResponse(**task)


@app.post("/api/tasks", response_model=TaskResponse, status_code=201)
def create_task(request: TaskCreateRequest):
    repos = get_project_map()
    if request.project not in repos:
        raise HTTPException(status_code=404, detail="Unknown project")

    task = create_and_submit_task(
        project=request.project,
        instruction=request.instruction,
        model=request.model,
        submitted_by="web-api",
    )
    app_logger.info("Queued task %s for project %s via API", task["task_id"], request.project)
    return TaskResponse(**task)


@app.get("/", response_class=HTMLResponse)
def index(request: Request):
    return templates.TemplateResponse(
        request=request,
        name="index.html",
        context={
            "projects": get_all_projects(),
            "tasks": get_recent_tasks(15),
            "auth_mode": AUTH_MODE,
        },
    )


@app.post("/submit", response_class=RedirectResponse)
def submit_form(
    project: str = Form(...),
    instruction: str = Form(...),
    model: str = Form(""),
):
    repos = get_project_map()
    if project not in repos:
        raise HTTPException(status_code=404, detail="Unknown project")

    task = create_and_submit_task(
        project=project,
        instruction=instruction,
        model=model or None,
        submitted_by="web-form",
    )
    app_logger.info("Queued task %s for project %s via web form", task["task_id"], project)
    return RedirectResponse(url=f"/tasks/{task['task_id']}", status_code=303)


@app.get("/tasks/{task_id}", response_class=HTMLResponse)
def task_detail(request: Request, task_id: str):
    task = get_task_by_id(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    return templates.TemplateResponse(
        request=request,
        name="task_detail.html",
        context={"task": task, "auth_mode": AUTH_MODE},
    )


@app.get("/status", response_class=HTMLResponse)
def status_page(request: Request):
    log_text, line_count = read_log_text()
    return templates.TemplateResponse(
        request=request,
        name="status.html",
        context={
            "auth_mode": AUTH_MODE,
            "log_text": log_text,
            "line_count": line_count,
            "log_file": str(APP_LOG_FILE),
        },
    )


@app.post("/status/clear", response_class=RedirectResponse)
def clear_status_log():
    ensure_log_dir()
    APP_LOG_FILE.write_text("", encoding="utf-8")
    return RedirectResponse(url="/status", status_code=303)
