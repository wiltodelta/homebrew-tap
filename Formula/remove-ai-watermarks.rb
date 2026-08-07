class RemoveAiWatermarks < Formula
  include Language::Python::Virtualenv

  desc "Remove visible and invisible AI watermarks from images"
  homepage "https://github.com/wiltodelta/remove-ai-watermarks"
  url "https://files.pythonhosted.org/packages/e0/42/5c46d3f7f2e6327aba9d0d6ae3eb2daf89583cb9f9d71fb47ac854310847/remove_ai_watermarks-0.26.1.tar.gz"
  sha256 "4557e10fa2856451df896d87e0158d0232ea5cad90e2c4f2d1359766ac18873b"
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
