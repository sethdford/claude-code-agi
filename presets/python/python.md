# Python Conventions

This preset covers best practices for Python projects with virtual environments, testing, type hints, and code quality.

## Virtual Environments

Use venv, Poetry, or uv for dependency management.

**Pattern (venv):**

```bash
python -m venv .venv
source .venv/bin/activate  # macOS/Linux
.venv\Scripts\activate      # Windows
pip install -r requirements.txt
```

**Pattern (Poetry):**

```bash
poetry init
poetry add package-name
poetry install
poetry run python script.py
```

**Pattern (uv):**

```bash
uv pip install -r requirements.txt
uv run python script.py
```

Never commit `.venv/`, `venv/`, or `.eggs/`. Use `requirements.txt` or `pyproject.toml` for reproducible installs.

## Type Hints

Use strict type hints with `mypy` in strict mode.

**Pattern:**

```python
from typing import Optional, List, Dict, Union
from dataclasses import dataclass

@dataclass
class User:
    id: int
    name: str
    email: str
    age: Optional[int] = None

def get_users(ids: List[int]) -> Dict[int, User]:
    """Fetch users by IDs."""
    return {}

def process_data(value: Union[str, int]) -> str:
    """Process either string or int."""
    return str(value)
```

**mypy configuration (.mypy.ini):**

```ini
[mypy]
python_version = 3.10
strict = True
warn_return_any = True
warn_unused_configs = True
disallow_untyped_defs = True
disallow_incomplete_defs = True
```

Always add return type annotations, even if it's `-> None`.

## Testing with pytest

Use pytest fixtures and parametrize for clean, reusable tests.

**Pattern:**

```python
import pytest
from app import create_user, get_user

@pytest.fixture
def db():
    """Setup test database."""
    # Setup
    db = {}
    yield db
    # Teardown

@pytest.mark.parametrize('email,expected_valid', [
    ('user@example.com', True),
    ('invalid', False),
    ('', False),
])
def test_email_validation(email, expected_valid):
    """Test email validation with multiple inputs."""
    result = is_valid_email(email)
    assert result == expected_valid

def test_create_user(db):
    """Test user creation with fixture."""
    user = create_user(db, 'john@example.com')
    assert user.id == 1
    assert user.email == 'john@example.com'

def test_get_user_not_found(db):
    """Test user fetch when not found."""
    with pytest.raises(ValueError, match='User not found'):
        get_user(db, 999)
```

**pytest.ini:**

```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = --strict-markers -v
```

Run with coverage: `pytest --cov=app tests/`

## Import Ordering

Use `isort` to enforce consistent import ordering.

**Pattern:**

```python
# stdlib
import os
import sys
from datetime import datetime
from typing import Optional

# third-party
import requests
import numpy as np
from django.db import models

# local
from app.models import User
from app.utils import helper_function
```

**pyproject.toml:**

```toml
[tool.isort]
profile = "black"
line_length = 88
```

Run `isort .` before committing.

## Code Formatting

Use Black for code formatting (opinionated, no configuration needed).

**Pattern:**

```bash
black .                    # Format all files
black --check .            # Check formatting without changes
```

## Linting

Use `ruff` for fast, comprehensive linting.

**pyproject.toml:**

```toml
[tool.ruff]
line-length = 88
target-version = "py310"
select = ["E", "F", "W", "I"]  # Errors, Pyflakes, Warnings, Import sorting
ignore = ["E501"]  # Line too long (Black handles this)
```

Run `ruff check .` before committing.

## Coverage

Use `pytest-cov` to enforce minimum coverage thresholds.

**Pattern:**

```bash
pytest --cov=app --cov-report=html tests/
```

**pyproject.toml:**

```toml
[tool.coverage.run]
source = ["app"]
omit = ["*/tests/*", "*/migrations/*"]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "raise AssertionError",
    "raise NotImplementedError",
    "if TYPE_CHECKING:",
]
min_coverage = 80
```

Fail CI if coverage drops below 80%.

## Django Patterns

**Model with managers:**

```python
from django.db import models

class PublishedManager(models.Manager):
    def get_queryset(self):
        return super().get_queryset().filter(published=True)

class Article(models.Model):
    title = models.CharField(max_length=200)
    published = models.BooleanField(default=False)

    objects = models.Manager()  # Default manager
    published_articles = PublishedManager()
```

**DRF Serializer:**

```python
from rest_framework import serializers
from app.models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'name', 'email']
        read_only_fields = ['id']
```

## FastAPI Patterns

**Basic endpoint:**

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

class Item(BaseModel):
    name: str
    price: float

@app.get("/items/{item_id}")
async def get_item(item_id: int) -> Item:
    """Get item by ID."""
    if item_id <= 0:
        raise HTTPException(status_code=400, detail="Invalid ID")
    return Item(name="Widget", price=9.99)

@app.post("/items")
async def create_item(item: Item) -> Item:
    """Create new item."""
    return item
```

## Common Mistakes

1. **Not using type hints** — Always add type annotations, even in simple functions
2. **Importing * from modules** — Use explicit imports for clarity
3. **Hardcoding values** — Use environment variables via `python-dotenv`
4. **Skipping tests** — Aim for 80% coverage minimum
5. **Ignoring linting warnings** — Fix them early; they compound
