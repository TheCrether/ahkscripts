CUR=$(pwd)

mkdir -p output

IFS=$'\n'
set -f
for f in $(find . -name '*.ahk'); do
	FDIR="${f%/*}" # get the directory

	TEMP="${f%*/}"
	TEMP="${TEMP/.\//}"
	OUT="./output/${TEMP%.ahk}" # construct the output directory
	mkdir -p "${OUT%/*}"        # create the output directory

	TEMP="${f##*/}"
	NAME="${TEMP%.ahk}" # get the name of the script for the icon
	ICON="./icons/$NAME.ico"
	if [[ -e $ICON ]]; then
		./.github/scripts/compile.bat "${f//\//\\}" "${OUT//\//\\}_32.exe" ".\\AutoHotkey\\AutoHotkeyU32.exe" ".\\AutoHotkey\\Compiler\\Unicode 32-bit.bin" $ICON
		./.github/scripts/compile.bat "${f//\//\\}" "${OUT//\//\\}_64.exe" ".\\AutoHotkey\\AutoHotkeyU64.exe" ".\\AutoHotkey\\Compiler\\Unicode 64-bit.bin" $ICON
	else
		./.github/scripts/compile.bat "${f//\//\\}" "${OUT//\//\\}_32.exe" ".\\AutoHotkey\\AutoHotkeyU32.exe" ".\\AutoHotkey\\Compiler\\Unicode 32-bit.bin"
		./.github/scripts/compile.bat "${f//\//\\}" "${OUT//\//\\}_64.exe" ".\\AutoHotkey\\AutoHotkeyU64.exe" ".\\AutoHotkey\\Compiler\\Unicode 64-bit.bin"
	fi
done
unset IFS
set +f
