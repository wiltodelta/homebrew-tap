# wiltodelta/tap

Homebrew formulae by [@wiltodelta](https://github.com/wiltodelta).

## remove-ai-watermarks

Remove visible and invisible AI watermarks from images (Gemini / Nano Banana,
ChatGPT, Stable Diffusion). [Source repo](https://github.com/wiltodelta/remove-ai-watermarks).

```sh
brew install wiltodelta/tap/remove-ai-watermarks
remove-ai-watermarks --help
```

The formula installs the CPU command surface: `identify`, `metadata`,
`visible`, and `erase` (cv2 backend). It requests the package's `visible` extra,
which is what brings in numpy and the binary opencv-python-headless wheel.

The diffusion-based `invisible` / `all` pipeline needs heavy ML dependencies
(torch, diffusers, multi-GB) **and an NVIDIA GPU** — every profile is CUDA-only,
with no CPU or MPS fallback — so it is kept out of the Homebrew install. Add it
with pip in your own Python environment when you need it:

```sh
pip install "remove-ai-watermarks[qwen-zimage]"
```

`qwen-zimage` is the extra that actually makes those commands run. The older
`gpu` alias no longer exists.

## Install any formula from this tap

`brew install wiltodelta/tap/<formula>`

Or tap first, then install:

```sh
brew tap wiltodelta/tap
brew install <formula>
```
