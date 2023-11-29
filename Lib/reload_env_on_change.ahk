#Requires AutoHotkey v2
;;; ABOUT
;;;  Respond to WM_SETTINGCHANGE messages and update this process's PATH
;;;  environment variable.
;;;
;;; USAGE
;;;  Run the script directly (e.g. double-click) or drag and drop onto
;;;  the AutoHotKey application.
;;;
;;; DEBUG
;;;  Optionally define a key binding to debug_show_recv_count, e.g.:
;;;    #space:: debug_show_recv_count()
;;;
;;; AUTHOR
;;;  piyo @ StackOverflow
;;;  TheCrether (modifications for all environment variables)
;;;
SysEnvPath := "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
UserEnvPath := "HKEY_CURRENT_USER\Environment"

setupReloadOnEnvChange() {
	OnMessage((WM_SETTINGCHANGE := 0x1A), recv_WM_SETTINGCHANGE)
	reset_env_from_registry()
}

;;
;; Respond to the WM_SETTINGCHANGE message.
;;
recv_WM_SETTINGCHANGE(wParam, lParam, msg, hwnd)
{
	global g_recv_WM_SETTINGCHANGE_count
	g_recv_WM_SETTINGCHANGE_count := g_recv_WM_SETTINGCHANGE_count + 1
	reset_env_from_registry()
}

resolve_env_variables(env_value, resolve_user := false) {
	regex := "%([a-zA-Z_()\{\}\[\]\$*+\-\/`"#',;.@!?]+)%"
	Found := RegExMatch(env_value, regex, &match)
	While Found > 0 and match.Count > 0 {
		normal := EnvGet(match[1])
		resolved := match[0]
		if resolve_user {
			resolved := RegRead(UserEnvPath, match[1], RegRead(SysEnvPath, match[1], normal))
		} else {
			resolved := RegRead(SysEnvPath, match[1], normal)
		}
		env_value := StrReplace(env_value, match[0], resolved)
		Found := RegExMatch(env_value, regex, &match, match.Pos + StrLen(resolved))
	}
	return env_value
}

;;
;; Import the recently changed Path environment variable from the
;; Windows Registry. Import from the System and User environments.
;;
reset_env_from_registry() {
	Loop Reg SysEnvPath {
		if (A_LoopRegType != "REG_SZ" && A_LoopRegType != "REG_EXPAND_SZ")
			continue
		if A_LoopRegName == "USERNAME"
			continue
		env_value := RegRead()
		env_value := resolve_env_variables(env_value, False)
		; OutputDebug(A_LoopRegName . "=" . env_value . "`n")
		EnvSet(A_LoopRegName, env_value)
	}

	Loop Reg UserEnvPath {
		if (A_LoopRegType != "REG_SZ" && A_LoopRegType != "REG_EXPAND_SZ")
			continue
		env_value := RegRead()
		env_value := resolve_env_variables(env_value, True)
		; OutputDebug(A_LoopRegName . "=" . env_value . "`n")
		EnvSet(A_LoopRegName, env_value)
	}

	; sys_path := resolve_env_variables(RegRead(SysEnvPath, "Path"))
	sys_path := RegRead(SysEnvPath, "Path")
	cu_path := resolve_env_variables(sys_path . ";" . RegRead(UserEnvPath, "Path"), true)
	; new_path := sys_path . ";" . cu_path
	OutputDebug("Path=" . cu_path . "`n")
	EnvSet("Path", cu_path)
}

; Debug var for interactive sanity checking
g_recv_WM_SETTINGCHANGE_count := 0

; Debug function for interactive sanity checking
debug_show_recv_count() {
	global g_recv_WM_SETTINGCHANGE_count
	path := ""
	path := EnvGet("PATH")
	msg := "g_recv_WM_SETTINGCHANGE := " . g_recv_WM_SETTINGCHANGE_count
	msg := msg . "!`n" . path
	MsgBox(msg)
}