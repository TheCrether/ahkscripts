#!/bin/bash
# Get the current version
VERSION=$(curl https://www.autohotkey.com/download/1.1/version.txt)
curl "https://www.autohotkey.com/download/1.1/AutoHotkey_$VERSION.zip" --output AutoHotkey.zip
unzip AutoHotkey.zip -d AutoHotkey "*.exe"
