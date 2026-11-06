# Free Claude Code — deploy em servidor free (Docker)
# Base: python:3.14.10-slim — o pyproject exige requires-python ==3.14.10
FROM python:3.14.10-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    # FCC lê HOST/PORT do ambiente. Render/Fly injetam PORT; o default aqui é 8082.
    HOST=0.0.0.0 \
    PORT=8082 \
    # Não abrir navegador no servidor (não há navegador lá).
    FCC_OPEN_BROWSER=false \
    # Config, chaves e sessões ficam em ~/.fcc (no Fly, monte um volume em /root/.fcc).
    HOME=/root

WORKDIR /app

# Dependências de build mínimas (uvicorn/fastapi não precisam de compilador na
# maioria dos wheels, mas grpcio pode precisar dele em slim).
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl ca-certificates build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copia só o necessário para instalar o pacote (o contexto é a raiz do repo).
COPY pyproject.toml uv.lock README.md LICENSE ./
COPY src ./src

RUN pip install --upgrade pip \
    && pip install . \
    && fcc-server --version

EXPOSE 8082

HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
    CMD curl -fsS http://127.0.0.1:${PORT:-8082}/health || exit 1

# fcc-server é o proxy FastAPI/Uvicorn. Mantém o processo em primeiro plano.
CMD ["fcc-server"]
