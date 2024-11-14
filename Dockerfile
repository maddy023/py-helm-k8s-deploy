# Build Stage where required binary / execuites , packages are build
FROM python:3.11-slim AS build-stage
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libhdf5-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean
COPY ./requirements.txt .
RUN pip install --no-cache-dir --upgrade -r /app/requirements.txt \
    && rm -rf /root/.cache/pip

# From preivous stage we copy only the packages / binaries that required application to run
FROM python:3.11-slim AS runtime-stage
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    libhdf5-103 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean
COPY --from=build-stage /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=build-stage /usr/local/bin /usr/local/bin
COPY /src /app
EXPOSE 80
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]