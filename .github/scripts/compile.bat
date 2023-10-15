IF "%4%" == "" (
	.\AutoHotkey\Compiler\Ahk2Exe.exe /in %1 /out %2 /base %3 /compress 0
) ELSE (
	.\AutoHotkey\Compiler\Ahk2Exe.exe /in %1 /out %2 /base %3 /icon %4 / compress 0
)
