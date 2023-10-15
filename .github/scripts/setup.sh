#!/bin/bash
# Get the current version
VERSION=$(curl https://www.autohotkey.com/download/2.0/version.txt)
curl "https://www.autohotkey.com/download/2.0/AutoHotkey_$VERSION.zip" --output AutoHotkey.zip
unzip AutoHotkey.zip -d AutoHotkey

# the following idea is taken from https://github.com/AutoHotkey/AutoHotkeyUX/blob/main/inc/GetGitHubReleaseAssetURL.ahk

release=$(curl https://api.github.com/repos/AutoHotkey/Ahk2Exe/releases/latest)
checkIfFound=$(echo $release | jq -r '.message')
if [[ "$checkIfFound" == "Not Found" ]]; then
	echo "Ahk2Exe could not be downloaded. Error:"
	echo "$release"
	exit 1
fi

assetLen=$(echo $release | jq -r '.assets | length')
found=""
url=""
for ((i = 0; i < $assetLen; i++)); do
	name=$(echo $release | jq -r ".assets[$i].name")
	if [[ "$name" =~ ^Ahk2Exe.*.zip$ ]]; then
		found="$name"
		url=$(echo $release | jq -r ".assets[$i].browser_download_url")
		break
	fi
done

echo $url
echo $found

if [[ ! "$found" =~ .zip$ ]]; then
	echo "Can't find a release asset which is a ZIP. Quitting. Release output:"
	echo "$release"
	exit 1
fi

curl "$url" --output Ahk2Exe.zip -L
unzip Ahk2Exe.zip -d Ahk2Exe
mkdir -p AutoHotkey/Compiler
cp Ahk2Exe/Ahk2Exe.zip AutoHotkey/Compiler
