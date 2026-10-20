FROM node:24-bookworm-slim AS upstream
ARG UPSTREAM_REV=e123a4721093efa55adac665e10a546c105eb117
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates python3 make g++ \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
RUN git init . && git remote add origin https://github.com/rollecode/cronometer-mcp.git \
    && git fetch --depth 1 origin "${UPSTREAM_REV}" && git checkout --detach FETCH_HEAD \
    && test "$(git rev-parse HEAD)" = "${UPSTREAM_REV}"
RUN npm ci --omit=dev && rm -rf .git tests

FROM python:3.12-slim-bookworm
RUN apt-get update && apt-get install -y --no-install-recommends libstdc++6 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=upstream /usr/local/bin/node /usr/local/bin/node
COPY --from=upstream /app /app
WORKDIR /app
# Docker port forwarding cannot reach a container's loopback interface.
# Publish only this authenticated gateway; keep the backend loopback-only.
RUN python - <<'PY'
from pathlib import Path
p = Path('auth-server.js')
source = p.read_text()
old = "app.listen(PORT, '127.0.0.1',"
assert source.count(old) == 1, 'Upstream listener changed; review before building'
p.write_text(source.replace(old, "app.listen(PORT, '0.0.0.0',").replace(
    'auth server on 127.0.0.1:', 'auth server on 0.0.0.0:'))
# Credential values are literal: never expand ${...} inside passwords.
p = Path('src/cronometer_mcp/server.py')
source = p.read_text()
old = 'load_dotenv(dotenv_path, override=False)'
assert source.count(old) == 1, 'Upstream dotenv loading changed; review before building'
p.write_text(source.replace(old, 'load_dotenv(dotenv_path, override=False, interpolate=False)'))
PY
RUN pip install --no-cache-dir '.[totp]' 'supervisor==4.3.0' && mkdir /backend
COPY supervisord.conf /etc/supervisord.conf
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
USER 10001:10001
ENTRYPOINT ["supervisord", "-c", "/etc/supervisord.conf"]
