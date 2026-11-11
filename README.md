# wiltodelta/tap

Homebrew formulae by [@wiltodelta](https://github.com/wiltodelta).

## remove-ai-watermarks

Clean AI watermarks and provenance in images, video, and text you generated or
edited. [Source repo](https://github.com/wiltodelta/remove-ai-watermarks).

```sh
brew install wiltodelta/tap/remove-ai-watermarks
remove-ai-watermarks --help
```

The default installation includes the package's `visible` extra for image detection
and visible-mark removal. Every published package extra has a matching
`--with-<extra>` flag. Combine flags to install the features you need:

```sh
# Experimental Seedance video processing, including FFmpeg and ffprobe.
brew install wiltodelta/tap/remove-ai-watermarks --with-video --with-diffusion

# The package's all group.
brew install wiltodelta/tap/remove-ai-watermarks --with-all

# Complete public backends, including OCR proposals and ONNX classification.
brew install wiltodelta/tap/remove-ai-watermarks --with-all --with-text-draft --with-classify-onnx

# Base package only, or a minimal custom selection.
brew install wiltodelta/tap/remove-ai-watermarks --without-default-extras
brew install wiltodelta/tap/remove-ai-watermarks --without-default-extras --with-heif

# List the options for the pinned package release.
brew options wiltodelta/tap/remove-ai-watermarks
```

Use `brew reinstall` with the same flags to add extras to an existing installation.
Homebrew retains selected flags on reinstall and upgrade. To remove previously
selected extras, uninstall the formula and install it again with the desired flags.
`--with-visible` explicitly enables image support when the base-only flag is retained.

Dependencies are resolved inside an isolated Homebrew Python environment.
Intel Macs automatically receive temporary Rust build tools from the official
Rust distribution, with a verified checksum, to compile current cryptography
dependencies. The compiler stays in the build directory. OpenSSL and pkgconf
are installed through Homebrew; no manual compiler setup is needed.
The `video` extra includes an offline FFmpeg/ffprobe bundle. Model weights download
on first use. Extras retain the package's platform and hardware requirements:
image regeneration needs NVIDIA CUDA; video VAE profiles support CPU, MPS, or CUDA
when the selected Torch stack supports the host platform. Selecting `--with-all`
does not make unsupported hardware compatible.

See the library's [installation guide](https://github.com/wiltodelta/remove-ai-watermarks/blob/main/docs/installation.md)
for the purpose of each extra and the platform requirements.

### Formula maintenance

```sh
bash maintain.sh
python3 scripts/sync_remove_ai_watermarks.py --version VERSION
```

The sync script validates the version-specific PyPI source archive and checksum,
then updates the complete `Provides-Extra` option inventory. The library's
release workflow runs it automatically. A new source version resets the formula
revision; syncing the same artifact preserves the revision.

## translate-like-me

A menu-bar app that translates the selected text in any app with a global
hotkey, in your own writing style, through Claude, ChatGPT or Grok.
Apple silicon, macOS 15 or later. [Source repo](https://github.com/wiltodelta/translate-like-me).

```sh
brew install --cask wiltodelta/tap/translate-like-me
```

The app updates itself with Sparkle, so `brew upgrade` leaves it alone.

## Install any formula from this tap

`brew install wiltodelta/tap/<formula>`

Or tap first, then install:

```sh
brew tap wiltodelta/tap
brew install <formula>
```

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for the
full text.
