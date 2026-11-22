cask "rota" do
  version "0.2.43"
  sha256 "7c61cb7fc96808b968a7153264339a1684f0a05b4858259242ee44933ee236f7"

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
