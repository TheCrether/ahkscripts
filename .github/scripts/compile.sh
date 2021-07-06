CUR=$(pwd)

mkdir -p output

IFS=$'\n'
set -f
for f in $(find . -name '*.ahk'); do
	FDIR="${f%/*}"
	TEMP="${f%*/}"
	TEMP="${TEMP/.\//}"
	OUT="./output/${TEMP%.ahk}"
	mkdir -p "${OUT%/*}"
	./.github/scripts/compile.bat "${f//\//\\}" "${OUT//\//\\}_32.exe" ".\\AutoHotkey\\AutoHotkeyU32.exe"
	./.github/scripts/compile.bat "${f//\//\\}" "${OUT//\//\\}_64.exe" ".\\AutoHotkey\\AutoHotkeyU64.exe"
	# ./Compiler/Ahk2Exe.exe '/in' $f '/out' $OUT

	# echo $FDIR $OUT
	# echo "dd" | tee $OUT
done
unset IFS
set +f
