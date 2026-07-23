class RemoveAiWatermarks < Formula
  include Language::Python::Virtualenv

  desc "Remove visible and invisible AI watermarks from images"
  homepage "https://github.com/wiltodelta/remove-ai-watermarks"
  url "https://files.pythonhosted.org/packages/31/e3/5c71fbc87a2975401a68cbf6aa9bba43d0172e99d604954f0e8f7fead238/remove_ai_watermarks-0.19.0.tar.gz"
  sha256 "730d3234f6959aeb37cfdda3cc32defd91f4fada47e510cd3e53f58a47c40ef8"
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
