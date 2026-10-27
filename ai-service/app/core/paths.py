"""Filesystem locations resolved relative to this package, never the cwd."""
from pathlib import Path

# app/core/paths.py -> project root is two levels above "core"
PROJECT_ROOT = Path(__file__).resolve().parents[2]
MODELS_DIR = PROJECT_ROOT / "models_store"
CONTENT_DIR = PROJECT_ROOT / "content" / "parsed"
