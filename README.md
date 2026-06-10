# wiltodelta/tap

Homebrew formulae by [@wiltodelta](https://github.com/wiltodelta).

## remove-ai-watermarks

Remove visible and invisible AI watermarks from images (Gemini / Nano Banana,
ChatGPT, Stable Diffusion). [Source repo](https://github.com/wiltodelta/remove-ai-watermarks).

```sh
brew install wiltodelta/tap/remove-ai-watermarks
remove-ai-watermarks --help
```

The formula installs the core command surface: `identify`, `metadata`,
`visible`, and `erase` (cv2 backend). The diffusion-based `invisible` / `all`
pipeline needs heavy ML dependencies (torch, diffusers, multi-GB), which are
kept out of the Homebrew install. Add them via the pip `gpu` extra into the
same Python environment if you need them:

```sh
pip install "remove-ai-watermarks[gpu]"
```

## Install any formula from this tap

`brew install wiltodelta/tap/<formula>`

Or tap first, then install:

```sh
brew tap wiltodelta/tap
brew install <formula>
```
