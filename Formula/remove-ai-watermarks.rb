class RemoveAiWatermarks < Formula
  include Language::Python::Virtualenv

  desc "Remove visible and invisible AI watermarks from images"
  homepage "https://github.com/wiltodelta/remove-ai-watermarks"
  url "https://files.pythonhosted.org/packages/e8/32/d915a7316e4864229c920bc98723a3430d7164a35c6e31d56d38a37c521a/remove_ai_watermarks-0.30.0.tar.gz"
  sha256 "0b3348442d5d319383a8dc2008835a063011cb6d7892f777b3a71b709f46c5a4"
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
