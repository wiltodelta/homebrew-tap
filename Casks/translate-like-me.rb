cask "translate-like-me" do
  version "3.7.15"
  sha256 "7608cccf2c073ea23fd7e38f4c06c975ab74aeb75327c4e92c5c90cea6e10ad2"

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
