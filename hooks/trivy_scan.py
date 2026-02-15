#!/usr/bin/env python3

import subprocess
import sys
import os


def run_command(cmd):
    """Komutu çalıştırır, stdout/stderr döner."""
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result


def check_docker():
    """Docker daemon'ın çalışıp çalışmadığını kontrol eder."""
    print("Docker kontrol ediliyor...")
    result = run_command(["docker", "info"])
    if result.returncode != 0:
        print("HATA: Docker çalışmıyor!")
        print("Lütfen Docker Desktop'ı başlatın ve tekrar deneyin.")
        print(result.stderr)
        sys.exit(1)
    print("OK: Docker çalışıyor.")


def pull_trivy():
    """Trivy Docker image'ını çeker."""
    image = "aquasec/trivy:latest"
    print(f"Trivy image çekiliyor: {image}")
    result = run_command(["docker", "pull", image])
    if result.returncode != 0:
        print(f"HATA: Trivy image çekilemedi!")
        print(result.stderr)
        sys.exit(1)
    print("OK: Trivy image hazır.")


def trivy_fs_scan():
    """Trivy ile filesystem taraması yapar."""
    repo_root = os.getcwd()
    print(f"Trivy filesystem scan başlatılıyor: {repo_root}")

    result = run_command([
        "docker", "run", "--rm",
        "-v", f"{repo_root}:/src",
        "aquasec/trivy:latest",
        "fs", "--exit-code", "1", "--severity", "CRITICAL,HIGH", "/src"
    ])

    print(result.stdout)

    if result.returncode != 0:
        print("HATA: Trivy taramasında CRITICAL/HIGH seviye zafiyet bulundu!")
        print(result.stderr)
        sys.exit(1)

    print("OK: Trivy taraması başarılı, kritik zafiyet bulunamadı.")


def main():
    print("=" * 50)
    print("Trivy Filesystem Security Scan")
    print("=" * 50)

    check_docker()
    pull_trivy()
    trivy_fs_scan()


if __name__ == "__main__":
    main()
