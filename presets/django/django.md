# Django Conventions

This preset covers best practices for Django projects with models, views, testing, and settings organization.

## Project Structure

Organize Django apps by feature, with clear separation of concerns.

**Pattern:**

```
myproject/
├── manage.py
├── db.sqlite3
├── requirements.txt
├── pyproject.toml
├── pytest.ini
├── myproject/
│   ├── __init__.py
│   ├── settings/
│   │   ├── __init__.py
│   │   ├── base.py
│   │   ├── dev.py
│   │   └── prod.py
│   ├── urls.py
│   ├── asgi.py
│   └── wsgi.py
├── apps/
│   ├── users/
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   ├── tests.py
│   │   ├── admin.py
│   │   └── migrations/
│   ├── articles/
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   ├── tests.py
│   │   ├── admin.py
│   │   └── migrations/
│   └── api/
│       ├── serializers.py
│       ├── views.py
│       ├── urls.py
│       └── tests.py
└── templates/
    └── base.html
```

Each app is self-contained and reusable.

## Settings Organization

Separate settings by environment (base, dev, prod).

**Pattern (settings/base.py):**

```python
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent.parent

SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-key-change-in-prod')
DEBUG = False

ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', 'localhost,127.0.0.1').split(',')

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'rest_framework',
    'apps.users',
    'apps.articles',
    'apps.api',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
]

ROOT_URLCONF = 'myproject.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
            ],
        },
    },
]

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME', 'myproject'),
        'USER': os.environ.get('DB_USER', 'postgres'),
        'PASSWORD': os.environ.get('DB_PASSWORD', ''),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
```

**Pattern (settings/dev.py):**

```python
from .base import *

DEBUG = True
ALLOWED_HOSTS = ['*']
DATABASES['default']['PASSWORD'] = 'dev-password'

INSTALLED_APPS += [
    'django_extensions',
    'debug_toolbar',
]

MIDDLEWARE += ['debug_toolbar.middleware.DebugToolbarMiddleware']

EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
INTERNAL_IPS = ['127.0.0.1']
```

**Pattern (settings/prod.py):**

```python
from .base import *

DEBUG = False
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS').split(',')

DATABASES['default']['PASSWORD'] = os.environ.get('DB_PASSWORD')

SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
CSRF_COOKIE_HTTPONLY = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_BROWSER_XSS_FILTER = True

EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = os.environ.get('EMAIL_HOST')
EMAIL_PORT = 587
EMAIL_USE_TLS = True
EMAIL_HOST_USER = os.environ.get('EMAIL_HOST_USER')
EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_HOST_PASSWORD')
```

**Pattern (manage.py):**

```python
#!/usr/bin/env python
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myproject.settings.dev')
```

Run with: `export DJANGO_SETTINGS_MODULE=myproject.settings.prod && python manage.py runserver`

## Models with Managers

Use custom managers for common queries.

**Pattern:**

```python
from django.db import models
from django.utils import timezone

class PublishedManager(models.Manager):
    def get_queryset(self):
        return super().get_queryset().filter(published=True)

class Article(models.Model):
    title = models.CharField(max_length=200)
    content = models.TextField()
    author = models.ForeignKey('users.User', on_delete=models.CASCADE)
    published = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = models.Manager()  # Default manager
    published_articles = PublishedManager()  # Custom manager

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['published', '-created_at']),
            models.Index(fields=['author']),
        ]

    def __str__(self):
        return self.title

    def publish(self):
        self.published = True
        self.save()
```

**Usage:**

```python
Article.objects.all()                      # All articles
Article.published_articles.all()           # Published only
Article.objects.filter(author=user)        # By author
```

## Views: Class-Based vs Function-Based

Prefer class-based views (CBV) for standardized patterns.

**Pattern (CBV):**

```python
from django.views import View
from django.views.generic import ListView, DetailView, CreateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.shortcuts import get_object_or_404
from .models import Article

class ArticleListView(ListView):
    model = Article
    paginate_by = 10
    context_object_name = 'articles'

    def get_queryset(self):
        return Article.published_articles.all()

class ArticleDetailView(DetailView):
    model = Article
    context_object_name = 'article'

class ArticleCreateView(LoginRequiredMixin, CreateView):
    model = Article
    fields = ['title', 'content']

    def form_valid(self, form):
        form.instance.author = self.request.user
        return super().form_valid(form)
```

**Pattern (function-based for custom logic):**

```python
from django.shortcuts import render, get_object_or_404
from django.http import JsonResponse
from .models import Article

def article_detail(request, pk):
    article = get_object_or_404(Article, pk=pk)
    # Custom logic here
    return render(request, 'articles/detail.html', {'article': article})
```

## DRF Serializers

Use DRF serializers for API validation and transformation.

**Pattern:**

```python
from rest_framework import serializers
from apps.users.models import User
from .models import Article

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email']
        read_only_fields = ['id']

class ArticleSerializer(serializers.ModelSerializer):
    author = UserSerializer(read_only=True)

    class Meta:
        model = Article
        fields = ['id', 'title', 'content', 'author', 'published', 'created_at']
        read_only_fields = ['id', 'created_at', 'author']

    def validate_title(self, value):
        if len(value) < 5:
            raise serializers.ValidationError("Title must be at least 5 characters.")
        return value
```

## Testing with pytest

Use pytest + pytest-django for testing.

**Pattern (pytest.ini):**

```ini
[pytest]
DJANGO_SETTINGS_MODULE = myproject.settings.dev
python_files = test_*.py
testpaths = .
addopts = --strict-markers -v --cov=apps --cov-report=html
```

**Pattern (conftest.py):**

```python
import pytest
from django.contrib.auth import get_user_model
from apps.articles.models import Article

User = get_user_model()

@pytest.fixture
def user():
    return User.objects.create_user(username='testuser', email='test@example.com')

@pytest.fixture
def article(user):
    return Article.objects.create(title='Test', content='Content', author=user)
```

**Pattern (test file):**

```python
import pytest

@pytest.mark.django_db
def test_article_creation(user):
    article = Article.objects.create(title='Test', content='Content', author=user)
    assert article.title == 'Test'
    assert article.author == user

@pytest.mark.django_db
def test_article_str(article):
    assert str(article) == 'Test'
```

## Migrations

Always generate migrations when models change.

**Pattern:**

```bash
python manage.py makemigrations                # Detect changes
python manage.py migrate                       # Apply migrations
python manage.py migrate --plan                # Preview migrations
```

Never manually edit migration files. Create a new migration if needed:

```bash
python manage.py makemigrations --empty myapp --name fix_field_type
```

## Common Mistakes

1. **Not using managers** — Always create custom managers for common queries
2. **Function-based views for standard patterns** — Use CBV for CRUD
3. **Hardcoding settings** — Always use environment variables
4. **No database indexes** — Add indexes for frequently queried fields
5. **Not separating dev/prod settings** — Always use settings modules
