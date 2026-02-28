FROM python:3.11-slim-bookworm

LABEL maintainer="Anwar Projects"
LABEL description="Proxmox Autoshutdown - Advanced VM Maintenance Automation"
LABEL version="2.0.0"

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates curl jq \
    && rm -rf /var/lib/apt/lists/*

# Copy application
COPY python/ /app/python/
COPY src/ /app/src/
COPY lib/ /app/lib/

# Install Python dependencies
RUN pip install --no-cache-dir -r /app/python/requirements.txt || true

# Health check
HEALTHCHECK --interval=30s --timeout=10s \
    CMD python -c "print('healthy')" || exit 1

WORKDIR /app
EXPOSE 9100

ENTRYPOINT ["python", "-m", "proxmox_autoshutdown"]
CMD ["--help"]
