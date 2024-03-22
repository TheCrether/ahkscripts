#Requires AutoHotkey v2
#SingleInstance force

; Always use folder where the script is
SetWorkingDir(A_ScriptDir)

Run(".\i3help.ahk")
Sleep(100)
Run(".\desktop.ahk")
Sleep(100)
Run(".\vowels.ahk")
Sleep(100)
Run(".\shortcuts.ahk")
Sleep(100)
Run(".\check_for_updates.ahk")
ExitApp