FROM ghcr.io/astral-sh/uv:python3.13-alpine AS build

WORKDIR /srv/http/

ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy \
    UV_PROJECT_ENVIRONMENT="archweb-env"

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev

RUN uv pip install --python archweb-env psycopg[binary] gunicorn

FROM python:3.13-alpine AS deploy

RUN apk add --no-cache git gcc musl-dev curl gpg gpg-agent rsync

LABEL Maintainer="corysanin@artixlinux.org"

WORKDIR /srv/http/archweb

COPY --chown=1000:1000 . .

COPY --from=build /srv/http/archweb-env /srv/http/archweb-env

ENV PATH="/srv/http/archweb-env/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DJANGO_SETTINGS_MODULE=settings

RUN addgroup -g 1000 -S appuser && adduser -G appuser -u 1000 -DS appuser && \
    mkdir -p ./config && \
    mkdir -p -m 700 /root/.gnupg/ && \
    cp ./local_settings.py.example ./config/local_settings.py && \
    ln -sf ./config/local_settings.py ./local_settings.py && \
    python manage.py collectstatic --noinput && \
    mkdir archweb && touch archweb/__init__.py && ln ./archweb.wsgi ./archweb/wsgi.py && \
    chown appuser:appuser .

USER appuser

CMD [ "gunicorn", "archweb.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "3" ]
