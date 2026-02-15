#!/usr/bin/env python3

import subprocess
import sys
import os
import io


def run_command(cmd):
    """Komutu calistirir, stdout/stderr doner."""
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result


def check_docker():
    """Docker daemon kontrol eder."""
    print("Docker kontrol ediliyor...")
    result = run_command(["docker", "info"])
    if result.returncode != 0:
        print("HATA: Docker calismiyior!")
        print("Lutfen Docker Desktop baslatin ve tekrar deneyin.")
        print(result.stderr)
        sys.exit(1)
    print("OK: Docker calisiyor.")


def pull_trivy():
    """Trivy Docker image ceker."""
    image = "aquasec/trivy:latest"
    print(f"Trivy image cekiliyor: {image}")
    result = run_command(["docker", "pull", image])
    if result.returncode != 0:
        print("HATA: Trivy image cekilemedi!")
        print(result.stderr)
        sys.exit(1)
    print("OK: Trivy image hazir.")


def trivy_fs_scan():
    """Trivy ile filesystem taramasi yapar."""
    repo_root = os.getcwd()
    print(f"Trivy filesystem scan baslatiliyor: {repo_root}")

    result = run_command([
        "docker", "run", "--rm",
        "-v", f"{repo_root}:/src",
        "aquasec/trivy:latest",
        "fs", "--exit-code", "1", "--severity", "CRITICAL,HIGH", "/src"
    ])

    print(result.stdout)

    if result.returncode != 0:
        print("HATA: Trivy taramasinda CRITICAL/HIGH seviye zafiyet bulundu!")
        print(result.stderr)
        sys.exit(1)

    print("OK: Trivy taramasi basarili, kritik zafiyet bulunamadi.")


def main():
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

    print("=" * 50)
    print("Trivy Filesystem Security Scan")
    print("=" * 50)

    check_docker()
    pull_trivy()
    trivy_fs_scan()


if __name__ == "__main__":
    main()
