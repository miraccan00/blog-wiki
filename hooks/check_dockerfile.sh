#!/usr/bin/env bash

set -e

echo "Repository Validation: Dockerfile kontrolü yapılıyor..."

if [ ! -f "Dockerfile" ]; then
    echo "HATA: Repoda 'Dockerfile' bulunamadı!"
    echo "Lütfen projenizin kök dizinine bir Dockerfile ekleyin."
    exit 1
fi

echo "OK: Dockerfile mevcut."
exit 0
