from setuptools import setup

setup(
    name="pre-commit-custom-hooks",
    version="0.1.0",
    py_modules=["trivy_scan"],
    package_dir={"": "hooks"},
    entry_points={
        "console_scripts": [
            "trivy-fs-scan=trivy_scan:main",
        ],
    },
)
