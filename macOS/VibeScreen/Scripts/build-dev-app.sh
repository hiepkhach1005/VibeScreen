#!/bin/zsh

set -euo pipefail

script_directory="${0:A:h}"
package_root="${script_directory:h}"
app_bundle="${package_root}/.build/VibeScreen.app"
contents_directory="${app_bundle}/Contents"
executable_directory="${contents_directory}/MacOS"
executable_path="${executable_directory}/VibeScreen"
info_plist="${contents_directory}/Info.plist"
resources_directory="${contents_directory}/Resources"
icon_source="${package_root}/Sources/VibeScreen/Resources/VibeScreenIcon.icns"
icon_destination="${resources_directory}/VibeScreenIcon.icns"

cd "${package_root}"
swift build -Xswiftc -DVIBESCREEN_DEVELOPMENT_FILE_CREDENTIALS
binary_directory="$(swift build --show-bin-path)"

mkdir -p "${executable_directory}" "${resources_directory}"
cp "${binary_directory}/VibeScreen" "${executable_path}"
cp "${package_root}/Sources/VibeScreen/Resources/Info.plist" "${info_plist}"
cp "${icon_source}" "${icon_destination}"

plutil -replace CFBundleExecutable -string VibeScreen "${info_plist}"
plutil -replace CFBundlePackageType -string APPL "${info_plist}"
plutil -replace CFBundleShortVersionString -string 0.1.0 "${info_plist}"
plutil -replace CFBundleVersion -string 1 "${info_plist}"
plutil -replace LSMinimumSystemVersion -string 14.0 "${info_plist}"

codesign --force --identifier com.vibescreen.mac --sign - "${app_bundle}"
print -u2 "Warning: this local debug app stores TV credentials as plaintext owner-only files in Application Support/VibeScreen/DevelopmentCredentials."
echo "${app_bundle}"
