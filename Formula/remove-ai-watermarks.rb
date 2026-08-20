class RemoveAiWatermarks < Formula
  include Language::Python::Virtualenv

  desc "Remove visible and invisible AI watermarks from images"
  homepage "https://github.com/wiltodelta/remove-ai-watermarks"
  url "https://files.pythonhosted.org/packages/e2/a8/08c6253ccbab5c9ba52112f43b500d69a19c8d18e103806eb7b7c72a37e2/remove_ai_watermarks-0.28.0.tar.gz"
  sha256 "827b6eb0a4eb3f16bb5a1f333e8b14067caae18172162f50d407c25c4c725228"
  license "Apache-2.0"

  depends_on "python@3.12"

  # Core install only: the metadata / identify / visible / erase (cv2) command
  # surface. pip resolves the binary numpy / opencv-python-headless wheels for
  # the host platform at install time. The heavy invisible / all pipeline needs
  # torch + diffusers (multi-GB); install those via the pip "gpu" extra instead:
  #   pip install "remove-ai-watermarks[gpu]"
  def install
    virtualenv_create(libexec, "python3.12")
    system libexec/"bin/python", "-m", "pip", "install", "--no-cache-dir", buildpath
    bin.install_symlink libexec/"bin/remove-ai-watermarks"
  end

  test do
    assert_match "Usage", shell_output("#{bin}/remove-ai-watermarks --help")
  end
end
