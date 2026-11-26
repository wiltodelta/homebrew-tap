cask "rota" do
  version "0.2.44"
  sha256 "2bb5d5fef7e4b9d2acc31077c6abac619aec26031557f63159799ae73965b11d"

  url "https://github.com/wiltodelta/rota/releases/download/v#{version}/Rota-v#{version}-macOS.zip"
  name "Rota"
  desc "Menu bar scheduler and session inbox for coding agents and shell commands"
  homepage "https://github.com/wiltodelta/rota"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on arch: :arm64
  depends_on macos: :sequoia

  app "Rota.app"

  uninstall quit: "com.wiltodelta.rota"

  zap trash: [
    "~/Library/Application Support/Rota",
    "~/Library/Caches/com.wiltodelta.rota",
    "~/Library/Caches/Rota",
    "~/Library/HTTPStorages/com.wiltodelta.rota",
    "~/Library/HTTPStorages/com.wiltodelta.rota.binarycookies",
    "~/Library/Logs/Rota",
    "~/Library/Preferences/com.wiltodelta.rota.plist",
  ]
end
