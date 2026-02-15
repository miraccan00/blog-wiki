# Pre-commit Custom Hooks

Bu repo, pre-commit framework'ü ile kullanılmak üzere özel hook'lar içerir.

## Mevcut Hook'lar

### repository-validation

Repoda `Dockerfile` dosyasının var olup olmadığını kontrol eder. Dockerfile bulunamazsa commit engellenir.

## Kullanım

Başka bir repoda bu hook'ları kullanmak için, o repodaki `.pre-commit-config.yaml` dosyasına şunu ekleyin:

```yaml
repos:
  - repo: https://github.com/miraccanyilmaz/blog-wiki
    rev: pre-commit-ozel-kontroller # git tag ile oluşturulan sabit versiyon
    hooks:
      - id: repository-validation
      - id: trivy-fs-scan
repos:
  - repo: https://github.com/miraccanyilmaz/blog-wiki
    rev: 67134d0d2cfd6b6f90adcba2fa29534ddb185e42 
    hooks:
      - id: repository-validation
      - id: trivy-fs-scan

```

Ardından:

```bash
pip install pre-commit
pre-commit install
```
