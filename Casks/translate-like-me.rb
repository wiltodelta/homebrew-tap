cask "translate-like-me" do
  version "3.4.2"
  sha256 "71c4be39d2947bbeeef52db2bc72a1d3690222e00968c9b49793b9e6ae9d4847"

  url "https://github.com/wiltodelta/translate-like-me/releases/download/v#{version}/Translate-Like-Me-v#{version}-macOS.zip"
  name "Translate Like Me"
  desc "Menu bar translator that replaces the selection in your own writing style"
  homepage "https://github.com/wiltodelta/translate-like-me"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on arch: :arm64
  depends_on macos: :sequoia

  app "Translate Like Me.app"

  uninstall quit: "com.wiltodelta.translatelikeme"

  zap trash: [
    "~/Library/Caches/com.wiltodelta.translatelikeme",
    "~/Library/HTTPStorages/com.wiltodelta.translatelikeme",
    "~/Library/HTTPStorages/com.wiltodelta.translatelikeme.binarycookies",
    "~/Library/Preferences/com.wiltodelta.translatelikeme.plist",
  ]
end
