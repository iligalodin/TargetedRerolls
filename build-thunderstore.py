#!/usr/bin/env python3
"""Build the upload ZIP for Thunderstore without staging generated files."""

from __future__ import annotations

import json
import struct
import subprocess
from pathlib import Path
from tempfile import NamedTemporaryFile
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parent
PACKAGE = "TargetedRerolls"
OUTPUT = ROOT / "dist"
SOURCE_ICON = ROOT / "assets" / "1x" / "icon.png"
PACKAGE_ICON = ROOT / "thunderstore" / "icon.png"


ROOT_FILES = (
    "TargetedRerolls.lua",
    "TargetedRerolls.json",
    "lovely.toml",
    "LICENSE",
    "blacklist.md",
)
PACKAGE_FILES = {
    "manifest.json": ROOT / "thunderstore" / "manifest.json",
    "README.md": ROOT / "thunderstore" / "README.md",
    "CHANGELOG.md": ROOT / "thunderstore" / "CHANGELOG.md",
    "icon.png": PACKAGE_ICON,
}
SOURCE_DIRECTORIES = ("assets", "localization", "src")


def require_file(path: Path) -> None:
    if not path.is_file():
        raise SystemExit(f"Missing required package file: {path.relative_to(ROOT)}")


def package_version() -> str:
    manifest_path = ROOT / "thunderstore" / "manifest.json"
    mod_path = ROOT / "TargetedRerolls.json"
    require_file(manifest_path)
    require_file(mod_path)

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    mod = json.loads(mod_path.read_text(encoding="utf-8"))
    version = manifest.get("version_number")

    if not isinstance(version, str) or not version:
        raise SystemExit("thunderstore/manifest.json must contain version_number")
    if mod.get("version") != version:
        raise SystemExit(
            "Version mismatch: thunderstore/manifest.json version_number and "
            "TargetedRerolls.json version must match"
        )

    return version

def png_dimensions(path: Path) -> tuple[int, int]:
    header = path.read_bytes()[:24]
    if header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise SystemExit(f"Package icon is not a PNG: {path.relative_to(ROOT)}")
    return struct.unpack(">II", header[16:24])


def build_package_icon() -> None:
    require_file(SOURCE_ICON)
    try:
        subprocess.run(
            [
                "ffmpeg",
                "-y",
                "-loglevel",
                "error",
                "-i",
                str(SOURCE_ICON),
                "-vf",
                "scale=256:256:flags=neighbor",
                "-frames:v",
                "1",
                "-update",
                "1",
                str(PACKAGE_ICON),
            ],
            check=True,
        )
    except FileNotFoundError:
        raise SystemExit("ffmpeg is required to build thunderstore/icon.png") from None
    except subprocess.CalledProcessError as error:
        raise SystemExit(f"Could not build thunderstore/icon.png: {error}") from error

    if png_dimensions(PACKAGE_ICON) != (256, 256):
        raise SystemExit("thunderstore/icon.png must be 256x256")


def archive_files() -> list[tuple[Path, Path]]:
    files: list[tuple[Path, Path]] = []

    for name in ROOT_FILES:
        source = ROOT / name
        require_file(source)
        files.append((source, Path(name)))

    for archive_name, source in PACKAGE_FILES.items():
        require_file(source)
        files.append((source, Path(archive_name)))

    for directory in SOURCE_DIRECTORIES:
        source_directory = ROOT / directory
        if not source_directory.is_dir():
            raise SystemExit(f"Missing required package directory: {directory}")
        for source in sorted(source_directory.rglob("*")):
            if source.is_file():
                files.append((source, source.relative_to(ROOT)))

    return files


def main() -> None:
    build_package_icon()
    version = package_version()
    archive_path = OUTPUT / f"{PACKAGE}-{version}.zip"
    files = archive_files()
    OUTPUT.mkdir(exist_ok=True)

    with NamedTemporaryFile(dir=OUTPUT, suffix=".zip", delete=False) as temporary:
        temporary_path = Path(temporary.name)

    try:
        with ZipFile(temporary_path, "w", compression=ZIP_DEFLATED) as archive:
            for source, archive_name in files:
                archive.write(source, archive_name.as_posix())
        temporary_path.replace(archive_path)
    finally:
        temporary_path.unlink(missing_ok=True)

    print(f"Built {archive_path.relative_to(ROOT)} ({len(files)} files)")


if __name__ == "__main__":
    main()
