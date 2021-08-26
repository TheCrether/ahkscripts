IF "%4%" == "" (
	.\AutoHotkey\Compiler\Ahk2Exe.exe /in %1 /out %2 /ahk %3
) ELSE (
	.\AutoHotkey\Compiler\Ahk2Exe.exe /in %1 /out %2 /ahk %3 /icon %4
)
