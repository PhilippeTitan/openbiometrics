FROM python:3.12-slim AS base

WORKDIR /app

# System deps for OpenCV, ONNX Runtime, and document processing
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 libglib2.0-0 libglib2.0-bin \
    libsm6 libxext6 libxrender1 \
    && rm -rf /var/lib/apt/lists/*

# Copy engine package first (dependency)
COPY engine/ engine/

# Install engine with all optional deps (face + document + liveness + person)
RUN cd engine && pip install --no-cache-dir ".[all]"

# Copy API package
COPY api/ api/

# Install API dependencies
RUN cd api && pip install --no-cache-dir .

# Copy model downloader and VERSION
COPY download_models.py VERSION ./

# Download face + document models into engine/models/ (API expects them there)
RUN python download_models.py --module face --models-dir ./engine/models \
    && python download_models.py --module document --models-dir ./engine/models

WORKDIR /app/api

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
