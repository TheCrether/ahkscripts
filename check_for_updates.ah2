#Include <Base>

if A_IsCompiled {
	; TODO check github tags
	ExitApp
}

CheckForGitUpdate() {
	SetWorkingDir(A_ScriptDir)
	RunWait(A_ComSpec . ' /c ".\check_for_updates.bat"', , "Hide")
	; https://stackoverflow.com/a/3278427 checking git status

	localRev := FileRead(".local.tmp")
	remoteRev := FileRead(".remote.tmp")
	baseRev := FileRead(".base.tmp")
	FileDelete(".\*.tmp")

	if localRev == remoteRev {
		Return
	}

	if localRev == baseRev {
		Result := MsgBox("There is an update for ahkscripts available.`nDo you want to 'git pull' and update?", "ahkscripts update available", "YesNo")
		if Result == "Yes" {
			RunWait(A_ComSpec . ' /c "git pull & pause"')
		}
	} else if remoteRev == baseRev {
		TrayTip("You need to push your changes`nRun 'git push' to update", "ahkscripts")
	}
}

CheckForGitUpdate()
SetTimer(CheckForGitUpdate, 1000 * 60 * 60 * 24)