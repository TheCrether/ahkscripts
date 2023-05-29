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

setupReloadOnEnvChange()
{
	OnMessage((WM_SETTINGCHANGE:=0x1A), "recv_WM_SETTINGCHANGE")
	reset_env_from_registry()
}

;;
;; Respond to the WM_SETTINGCHANGE message.
;;
recv_WM_SETTINGCHANGE(wParam, lParam, msg, hwnd)
{
	global g_recv_WM_SETTINGCHANGE_count
	g_recv_WM_SETTINGCHANGE_count := g_recv_WM_SETTINGCHANGE_count + 1
	;;debug;; ToolTip Received a WM_SETTINGCHANGE !
	reset_env_from_registry()
}

;;
;; Import the recently changed Path environment variable from the
;; Windows Registry. Import from the System and User environments.
;;
reset_env_from_registry()
{
	sys_path := ""
	sys_subkey := "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
	cu_path := ""
	cu_subkey := "Environment"

	Loop, Reg, HKEY_LOCAL_MACHINE\%sys_subkey%
	{
		if(A_LoopRegType != "REG_SZ" && A_LoopRegType != "REG_EXPAND_SZ")
			continue
		RegRead, value
		EnvSet, %A_LoopRegName%, %value% ; TODO check if value is another environment variable
	}

	Loop, Reg, HKEY_CURRENT_USER\%cu_subkey%
	{
		if(A_LoopRegType != "REG_SZ" && A_LoopRegType != "REG_EXPAND_SZ")
			continue
		RegRead, value
		EnvSet, %A_LoopRegName%, %value% ; TODO check if value is another environment variable
	}

	RegRead, sys_path, HKEY_LOCAL_MACHINE, %sys_subkey%, Path
	RegRead, cu_path, HKEY_CURRENT_USER, %cu_subkey%, Path
	new_path := sys_path . ";" . cu_path
	;;debug;; MsgBox,% new_path
	EnvSet, PATH,% new_path
}

;;;

; Debug var for interactive sanity checking
g_recv_WM_SETTINGCHANGE_count := 0

; Debug function for interactive sanity checking
debug_show_recv_count() {
	global g_recv_WM_SETTINGCHANGE_count
	path := ""
	EnvGet, path, PATH
	msg := "g_recv_WM_SETTINGCHANGE := " . g_recv_WM_SETTINGCHANGE_count
	msg := msg . "!`n" . path
	MsgBox,% msg
}