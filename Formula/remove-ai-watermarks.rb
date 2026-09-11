class RemoveAiWatermarks < Formula
  include Language::Python::Virtualenv

  desc "Remove visible and invisible AI watermarks from images"
  homepage "https://github.com/wiltodelta/remove-ai-watermarks"
  url "https://files.pythonhosted.org/packages/a3/71/5cae74c17b37a9223fe5ede77285dc2178d65b83206ca9aa6a2eba573ef4/remove_ai_watermarks-0.40.1.tar.gz"
  sha256 "98a79e7fb9da2c10ece81981e025d27afe3808844de2142c9bf3773c160e2413"
  license "Apache-2.0"

  depends_on "python@3.12"

  # The metadata / identify / visible / erase (cv2) command surface. The
  # "visible" extra is what pulls numpy and the binary opencv-python-headless
  # wheel; the bare package installs neither, so requesting it here is what makes
  # `visible` and `erase` runnable rather than a documented promise. The heavy
  # invisible / all pipeline needs torch + diffusers (multi-GB) AND an NVIDIA GPU,
  # so it stays out of the formula; install it with pip into your own environment:
  #   pip install "remove-ai-watermarks[qwen-zimage]"
  # ("gpu" was an old alias and is deliberately not provided any more.)
  def install
    virtualenv_create(libexec, "python3.12")
    system libexec/"bin/python", "-m", "pip", "install", "--no-cache-dir", "#{buildpath}[visible]"
    bin.install_symlink libexec/"bin/remove-ai-watermarks"
  end

  test do
    assert_match "Usage", shell_output("#{bin}/remove-ai-watermarks --help")

    # The README promises `visible` and `erase`, and both need the pixel runtime.
    # Assert the dependency is really in the virtualenv: the formula shipped for
    # several releases installing the bare package, where every pixel command
    # failed while `--help` still passed and this test still went green.
    system libexec/"bin/python", "-c", "import cv2, numpy"

    # A real end-to-end pixel run, not just an import: generate a small PNG and
    # erase a region from it, which exercises the cv2 inpaint path the tap
    # advertises. `identify` covers the metadata surface on the same file.
    system libexec/"bin/python", "-c", <<~PYTHON
      import numpy, cv2
      cv2.imwrite("#{testpath}/sample.png", numpy.full((128, 128, 3), 200, numpy.uint8))
    PYTHON
    system bin/"remove-ai-watermarks", "erase", testpath/"sample.png",
           "--region", "8,8,32,32", "-o", testpath/"erased.png"
    assert_path_exists testpath/"erased.png"
    assert_match "Verdict", shell_output("#{bin}/remove-ai-watermarks identify #{testpath}/sample.png")
  end
end
