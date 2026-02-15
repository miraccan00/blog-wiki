# Pre-commit Custom Hooks

Bu repo, pre-commit framework'ü ile kullanılmak üzere özel hook'lar içerir.

## Mevcut Hook'lar

### repository-validation

Repoda `Dockerfile` dosyasının var olup olmadığını kontrol eder. Dockerfile bulunamazsa commit engellenir.

## Kullanım

Başka bir repoda bu hook'ları kullanmak için, o repodaki `.pre-commit-config.yaml` dosyasına şunu ekleyin:

```yaml
repos:
  - repo: https://github.com/miraccan00/blog-wiki
    rev: v0.1.0  # git tag veya commit hash kullanın
    hooks:
      - id: repository-validation
      - id: trivy-fs-scan
```

Ardından:

```bash
pip install pre-commit
pre-commit install
```
