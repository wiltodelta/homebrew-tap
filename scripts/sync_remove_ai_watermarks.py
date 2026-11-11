"""Synchronize the tap formula with one exact published package release."""

from __future__ import annotations

import argparse
import json
import logging
import re
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import quote

log = logging.getLogger(__name__)
BEGIN = "  # BEGIN PACKAGE EXTRAS"
END = "  # END PACKAGE EXTRAS"


@dataclass(frozen=True)
class Release:
    version: str
    url: str
    sha256: str
    extras: tuple[str, ...]


def parse_release(payload: dict, version: str, url: str | None, sha256: str | None) -> Release:
    """Validate the target and read all extras, including dependency-free groups."""
    info = payload["info"]
    if info["name"] != "remove-ai-watermarks" or info["version"] != version:
        raise ValueError("PyPI response does not describe the requested package release")
    if info.get("yanked"):
        raise ValueError("Refusing a yanked package release")
    source = next(f for f in payload["urls"] if f["packagetype"] == "sdist")
    actual_url, actual_sha = source["url"], source["digests"]["sha256"]
    if url is not None and url != actual_url:
        raise ValueError("Source URL disagrees with the resolved release")
    if sha256 is not None and sha256 != actual_sha:
        raise ValueError("Source digest disagrees with the resolved release")
    if not re.fullmatch(r"https://files\.pythonhosted\.org/packages/[A-Za-z0-9_./%+-]+\.tar\.gz", actual_url):
        raise ValueError("Source URL is not a safe PyPI source archive URL")
    if not re.fullmatch(r"[0-9a-f]{64}", actual_sha):
        raise ValueError("Invalid source SHA-256 digest")
    extras = info.get("provides_extra")
    if not isinstance(extras, list) or not extras:
        raise ValueError("Published Provides-Extra metadata is missing")
    if not all(isinstance(extra, str) and re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", extra) for extra in extras):
        raise ValueError("Published extras must be canonical option names")
    if "visible" not in extras:
        raise ValueError("The formula's default visible extra is missing")
    return Release(version, actual_url, actual_sha, tuple(sorted(set(extras))))


def replace_one(pattern: str, replacement: str, text: str) -> str:
    """Fail closed when the maintained formula shape changed."""
    updated, count = re.subn(pattern, lambda _match: replacement, text, flags=re.MULTILINE)
    if count != 1:
        raise ValueError(f"Expected one formula field for {pattern!r}, found {count}")
    return updated


def render_formula(text: str, release: Release) -> str:
    """Update the artifact and option inventory without changing formula behavior."""
    old_url = re.search(r'^  url "([^"]+)"$', text, re.MULTILINE)
    if old_url is None:
        raise ValueError("Formula source URL is missing")
    updated = replace_one(r'^  url "[^"]+"$', f'  url "{release.url}"', text)
    updated = replace_one(r'^  sha256 "[^"]+"$', f'  sha256 "{release.sha256}"', updated)
    block = "\n".join([BEGIN, "  PACKAGE_EXTRAS = %w[", *(f"    {e}" for e in release.extras), "  ].freeze", END])
    updated = replace_one(re.escape(BEGIN) + r"[\s\S]*?" + re.escape(END), block, updated)
    if old_url[1] != release.url:
        updated = re.sub(r"^  revision [0-9]+\n", "", updated, flags=re.MULTILINE)
    return updated


def fetch_release(version: str) -> dict:
    """Read the versioned PyPI response, without following the moving latest release."""
    url = f"https://pypi.org/pypi/remove-ai-watermarks/{quote(version, safe='')}/json"
    log.info("PyPI request: method=GET url=%s", url)
    try:
        with urllib.request.urlopen(url, timeout=30) as response:
            body = response.read().decode("utf-8")
            log.info("PyPI response: status=%s body=%s", response.status, body)
    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8", errors="replace")
        log.error("PyPI response: status=%s body=%s", error.code, body)
        raise
    return json.loads(body)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--formula", type=Path, default=Path("Formula/remove-ai-watermarks.rb"))
    parser.add_argument("--version")
    parser.add_argument("--url")
    parser.add_argument("--sha256")
    parser.add_argument("--check", action="store_true", help="Check without writing the formula")
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    try:
        original = args.formula.read_text()
        version = args.version
        if version is None:
            match = re.search(r'remove_ai_watermarks-([^"/]+)\.tar\.gz', original)
            if match is None:
                raise ValueError("Could not resolve the pinned formula version")
            version = match[1]
        release = parse_release(fetch_release(version), version, args.url, args.sha256)
        updated = render_formula(original, release)
        if args.check:
            if updated != original:
                raise ValueError("Formula artifact or extras are out of sync with its published package")
        elif updated != original:
            temporary = args.formula.with_suffix(".rb.tmp")
            try:
                temporary.write_text(updated)
                temporary.replace(args.formula)
            finally:
                temporary.unlink(missing_ok=True)
        log.info("Formula matches package %s, extras=%s", release.version, ",".join(release.extras))
    except (OSError, ValueError, KeyError, StopIteration, TypeError) as error:
        log.exception("Formula synchronization failed: %s", error)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
