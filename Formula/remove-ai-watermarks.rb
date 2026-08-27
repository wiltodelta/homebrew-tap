class RemoveAiWatermarks < Formula
  include Language::Python::Virtualenv

  desc "Remove visible and invisible AI watermarks from images"
  homepage "https://github.com/wiltodelta/remove-ai-watermarks"
  url "https://files.pythonhosted.org/packages/a1/07/9ce4bdccf867e048fcba5b5ccf5163728a427c3d9061d586b2fe9848177e/remove_ai_watermarks-0.32.0.tar.gz"
  sha256 "996700b07741356aecdb29a9cc921906ef3d7d0cdc62444b801de9563923fdfb"
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
