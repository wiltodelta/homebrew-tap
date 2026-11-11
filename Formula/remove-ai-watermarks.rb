class RemoveAiWatermarks < Formula
  include Language::Python::Virtualenv

  desc "Clean AI watermarks and provenance in images, video, and text"
  homepage "https://github.com/wiltodelta/remove-ai-watermarks"
  url "https://files.pythonhosted.org/packages/18/78/fbf02b828eea467169bffbac986ef011625aec02e91a72a64fb4b31146a1/remove_ai_watermarks-0.57.0.tar.gz"
  sha256 "9ccd9c339189d333c942f8013b7dac85e557b0783f7f62310a0af4688218a46f"
  license "Apache-2.0"
  revision 1

  option "without-default-extras", "Skip the default visible image support"

  depends_on "python@3.12"

  on_macos do
    on_intel do
      depends_on "pkgconf" => :build
      depends_on "openssl@3"

      # Secure cryptography releases require a source build on Intel Macs.
      # Bootstrap the compiler from Rust's official release distribution instead
      # of building Homebrew's full Rust/LLVM toolchain from source.
      resource "rust-build-toolchain" do
        url "https://static.rust-lang.org/dist/rust-1.99.1-x86_64-apple-darwin.tar.xz"
        sha256 "13b237d0294bad3bb7b18d559517947ed8348ea25812fa3b468c904996f80e34"
      end
    end
  end

  preserve_rpath

  # BEGIN PACKAGE EXTRAS
  PACKAGE_EXTRAS = %w[
    all
    classify
    classify-onnx
    detect
    dev
    diffusion
    heif
    lama
    migan
    pixels
    qwen-zimage
    source-classify
    text-draft
    text-restoration
    trustmark
    video
    visible
  ].freeze
  # END PACKAGE EXTRAS
  PACKAGE_EXTRAS.each do |extra|
    option "with-#{extra}", "Install the #{extra} package extra"
  end

  def selected_extras
    extras = PACKAGE_EXTRAS.select { |extra| build.with? extra }
    extras << "visible" if build.with? "default-extras"
    extras.uniq.sort
  end

  def install
    prepare_intel_build_tools
    virtualenv_create(libexec, "python3.12", system_site_packages: false)
    extras = selected_extras
    target = extras.empty? ? buildpath.to_s : "#{buildpath}[#{extras.join(",")}]"
    # Use Homebrew's pip driver to target the isolated, pip-free environment.
    # Dependency resolution stays enabled so each requested extra is complete.
    system "python3.12", "-m", "pip", "--python=#{libexec}/bin/python", "install", target
    preserve_wheel_linkage
    bin.install_symlink libexec/"bin/remove-ai-watermarks"
  end

  def prepare_intel_build_tools
    return unless OS.mac?
    return unless Hardware::CPU.intel?

    toolchain = buildpath/"rust-build-toolchain"
    resource("rust-build-toolchain").stage do
      system "./install.sh", "--prefix=#{toolchain}",
             "--components=rustc,cargo,rust-std-x86_64-apple-darwin", "--disable-ldconfig"
    end
    ENV.prepend_path "PATH", toolchain/"bin"
    ENV["OPENSSL_DIR"] = formula_opt_prefix("openssl@3")
  end

  def preserve_wheel_linkage
    return unless OS.mac?

    # Wheels carry their own relative dependency paths. PyAV also ships short
    # absolute dylib IDs whose headers cannot fit Homebrew's full opt path.
    libexec.glob("**/*.dylib", File::FNM_DOTMATCH).each do |path|
      next if path.symlink?

      library = MachOPathname.wrap(path)
      next if library.dylib_id.start_with?("@rpath")

      library.change_dylib_id("@rpath/#{path.basename}")
      system "/usr/bin/codesign", "--force", "--sign", "-", path
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/remove-ai-watermarks --version")

    system libexec/"bin/python", "-c", <<~PYTHON
      from PIL import Image
      Image.new("RGB", (128, 128), (200, 200, 200)).save("sample.png")
    PYTHON
    assert_match "Verdict", shell_output("#{bin}/remove-ai-watermarks identify sample.png --no-visible")

    if selected_extras.empty?
      system libexec/"bin/python", "-c", <<~PYTHON
        import importlib.util
        assert all(importlib.util.find_spec(name) is None for name in ("cv2", "torch", "av"))
      PYTHON
    end

    if selected_extras.include? "visible"
      system libexec/"bin/python", "-c", "import cv2, numpy"
      system bin/"remove-ai-watermarks", "erase", testpath/"sample.png",
             "--region", "8,8,32,32", "-o", testpath/"erased.png"
      assert_path_exists testpath/"erased.png"
    end

    if selected_extras.intersect?(%w[all dev video])
      system libexec/"bin/python", "-c", <<~PYTHON
        import os
        import subprocess
        from remove_ai_watermarks.video import identify_video
        from remove_ai_watermarks.video_tools import require_video_tool

        os.environ["PATH"] = ""
        ffmpeg = require_video_tool("ffmpeg")
        ffprobe = require_video_tool("ffprobe")
        subprocess.run([ffprobe, "-version"], check=True, capture_output=True)
        subprocess.run([
            ffmpeg, "-v", "error", "-f", "lavfi", "-i",
            "color=c=black:s=32x32:r=2:d=1", "-c:v", "libx264", "clip.mp4",
        ], check=True, capture_output=True)
        assert identify_video("clip.mp4").total_frames == 2
      PYTHON
    end

    if selected_extras.intersect?(%w[all diffusion qwen-zimage text-restoration])
      # Import the real VAE class without downloading model weights or using a GPU.
      system libexec/"bin/python", "-c", <<~PYTHON
        from diffusers import AutoencoderKL
        from remove_ai_watermarks.video_invisible import is_available
        assert is_available()
      PYTHON
    end
  end
end
