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
		./.github/scripts/compile.bat "${f//\//\\}" "${OUT//\//\\}_32.exe" ".\\AutoHotkey\\AutoHotkey32.exe" $ICON
		./.github/scripts/compile.bat "${f//\//\\}" "${OUT//\//\\}_64.exe" ".\\AutoHotkey\\AutoHotkey64.exe" $ICON
	else
		./.github/scripts/compile.bat "${f//\//\\}" "${OUT//\//\\}_32.exe" ".\\AutoHotkey\\AutoHotkey32.exe"
		./.github/scripts/compile.bat "${f//\//\\}" "${OUT//\//\\}_64.exe" ".\\AutoHotkey\\AutoHotkey64.exe"
	fi
done
unset IFS
set +f
