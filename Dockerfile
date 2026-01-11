FROM ghcr.io/astral-sh/uv:python3.13-alpine AS build

WORKDIR /usr/src/web

ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev

RUN uv pip install --python .venv psycopg[binary]

FROM python:3.13-alpine AS deploy

RUN apk add --no-cache git gcc musl-dev curl gpg gpg-agent rsync

LABEL Maintainer="corysanin@artixlinux.org"

WORKDIR /usr/src/web

COPY . .

COPY --from=build /usr/src/web/.venv /usr/src/web/.venv

ENV PATH="/usr/src/web/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

RUN addgroup -g 1000 -S appuser && adduser -G appuser -u 1000 -DS appuser && \
    mkdir -p ./config && \
    mkdir -p -m 700 /root/.gnupg/ && \
    cp ./local_settings.py.example ./config/local_settings.py && \
    ln -sf ./config/local_settings.py ./local_settings.py && \
    python manage.py collectstatic --noinput && \
    chown -R appuser:appuser .

USER appuser

CMD [ "python", "manage.py", "runserver", "0.0.0.0:8000" ]
