IF "%5%" == "" (
	.\AutoHotkey\Compiler\Ahk2Exe.exe /in %1 /out %2 /ahk %3 /base %4
) ELSE (
	.\AutoHotkey\Compiler\Ahk2Exe.exe /in %1 /out %2 /ahk %3 /base %4 /icon %5
)
