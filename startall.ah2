#Requires AutoHotkey v2
#SingleInstance force

; Always use folder where the script is
SetWorkingDir(A_ScriptDir)

Run(".\i3help.ah2")
Sleep(100)
Run(".\desktop.ah2")
Sleep(100)
Run(".\vowels.ah2")
Sleep(100)
Run(".\explorer.ah2")
ExitApp