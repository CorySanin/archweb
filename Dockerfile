FROM python:3.13-alpine AS base

RUN apk add --no-cache git gcc musl-dev curl gpg gpg-agent rsync

FROM base AS deploy

LABEL Maintainer="corysanin@artixlinux.org"

WORKDIR /usr/src/web

COPY . .

COPY overlay .

RUN mkdir -p ./config && \
    mkdir -p -m 700 /root/.gnupg/ && \
    cp ./local_settings.py.example ./config/local_settings.py && \
    ln -sf ./config/local_settings.py ./local_settings.py && \
    python -m venv ./env/ && \
    env/bin/pip install -r requirements.txt && \
    env/bin/pip install "psycopg[binary]" && \
    env/bin/python manage.py collectstatic --noinput

ENV VIRTUAL_ENV=/usr/src/web/env
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ENV PYTHONUNBUFFERED=1

CMD [ "python", "manage.py", "runserver", "0.0.0.0:8000" ]