#!/usr/bin/env bash

set -e

echo "=================================================="
echo "Trivy Filesystem Security Scan"
echo "=================================================="

# Docker kontrolü
echo "Docker kontrol ediliyor..."
if ! docker info > /dev/null 2>&1; then
    echo "HATA: Docker çalışmıyor!"
    echo "Lütfen Docker Desktop'ı başlatın ve tekrar deneyin."
    exit 1
fi
echo "OK: Docker çalışıyor."

# Trivy image pull
IMAGE="aquasec/trivy:latest"
echo "Trivy image çekiliyor: ${IMAGE}"
if ! docker pull "${IMAGE}"; then
    echo "HATA: Trivy image çekilemedi!"
    exit 1
fi
echo "OK: Trivy image hazır."

# Filesystem scan
REPO_ROOT="$(pwd)"
echo "Trivy filesystem scan başlatılıyor: ${REPO_ROOT}"

SCAN_OUTPUT=$(docker run --rm -v "${REPO_ROOT}:/src" "${IMAGE}" fs --exit-code 1 --severity CRITICAL,HIGH /src 2>&1) || {
    echo "${SCAN_OUTPUT}"
    echo "HATA: Trivy taramasında CRITICAL/HIGH seviye zafiyet bulundu!"
    exit 1
}

echo "${SCAN_OUTPUT}"
echo "OK: Trivy taraması başarılı, kritik zafiyet bulunamadı."
