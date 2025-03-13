#!/bin/bash
docker build -t cs598p1-common -f cs598p1-common.Dockerfile . && \
    docker build -t cs598p1-main -f cs598p1-main.Dockerfile . && \
    docker build -t cs598p1-worker -f cs598p1-worker.Dockerfile . && \
    docker compose -f cs598p1-compose.yaml up
