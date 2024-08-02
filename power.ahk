; TODO icon
;@Ahk2Exe-SetDescription battery sets various settings when a laptop is connected to the charger or on battery

#Include <Base>

SetIcon("./icons/power.ico")

class PowerStatus {
	/**
	 * The AC power status. This member can be one of the following values.
	 * 0 => Offline
	 * 1 => Online
	 * 255 => Unknown status
	 * @type {Integer}
	 */
	ACLineStatus := 0

	/**
	 * bitmask for different cases like battery high and charging
	 * 1 => High—the battery capacity is at more than 66 percent
	 * 2 => Low—the battery capacity is at less than 33 percent
	 * 4 => Critical—the battery capacity is at less than five percent
	 * 8 => Charging
	 * 128 => No system battery
	 * 255 => Unknown status—unable to read the battery flag information
	 * @type {Integer}
	 */
	BatteryFlag := 0

	/**
	 * the exact battery percent
	 * @type {Integer}
	 */
	BatteryLifePercent := 0

	/**
	 * The status of battery saver.
	 * To participate in energy conservation, avoid resource intensive tasks when battery saver is on.
	 * 0 => Battery saver is off.
	 * 1 => Battery saver on. Save energy where possible.
	 */
	SystemStatusFlag := 0

	/**
	 * The number of seconds of battery life remaining, or –1 if
	 * remaining seconds are unknown or if the device is connected to AC power.
	 */
	BatteryLifeTime := 0

	/**
	 * The number of seconds of battery life when at full charge, or –1 if
	 * full battery lifetime is unknown or if the device is connected to AC power.
	 */
	BatteryFullLifeTime := 0

	High => this.BatteryFlag & 1 == 1
	Low => this.BatteryFlag & 2 == 2
	Critical => this.BatteryFlag & 4 == 4
	Charging => this.BatteryFlag & 8 == 8
	NoBattery => this.BatteryFlag & 128 == 128
	Unknown => this.BatteryFlag & 255 == 255
}
/**
 * gets the system power status
 * @returns {PowerStatus} status object
 */
GetSystemPowerStatus()
{
	local fetchedStatus := Buffer(12)

	if !DllCall("kernel32.dll\GetSystemPowerStatus", "Ptr", fetchedStatus)
		return false

	/** @type {PowerStatus} */
	status := PowerStatus()

	status.ACLineStatus := NumGet(fetchedStatus, 0, "uchar")
	status.BatteryFlag := NumGet(fetchedStatus, 1, "uchar")
	status.BatteryLifePercent := NumGet(fetchedStatus, 2, "uchar")
	status.SystemStatusFlag := NumGet(fetchedStatus, 3, "uchar")
	status.BatteryLifeTime := NumGet(fetchedStatus, 4, "Int")
	status.BatteryFullLifeTime := NumGet(fetchedStatus, 8, "Int")

	return status
}

; documentation here: https://learn.microsoft.com/en-us/windows/win32/power/wm-powerbroadcast
; all constants: https://microsoft.github.io/windows-docs-rs/doc/windows/Win32/UI/WindowsAndMessaging/index.html?search=PBT_

global WM_POWERBROADCAST := 0x218

; Power status has changed
global PBT_APMPOWERSTATUSCHANGE := 0xA

; Operation is resuming automatically from a low-power state
global PBT_APMRESUMEAUTOMATIC := 0x12

; Operation is resuming from a low-power state.
; This message is sent after PBT_APMRESUMEAUTOMATIC
; if the resume is triggered by user input
global PBT_APMRESUMESUSPEND := 0x7

; System is suspending operation
global PBT_APMSUSPEND := 0x4

; A power setting change event has been received.
global PBT_POWERSETTINGSCHANGE := 0x8013

; taken from rust docs
global PBT_APMSTANDBY := 5
global PBT_APMOEMEVENT := 11
global PBT_APMBATTERYLOW := 9
global PBT_APMQUERYSTANDBY := 1
global PBT_APMQUERYSUSPEND := 0
global PBT_APMRESUMESTANDBY := 8
global PBT_APMRESUMECRITICAL := 6
global PBT_APMQUERYSTANDBYFAILED := 3
global PBT_APMQUERYSUSPENDFAILED := 2

global types := [
	"WM_POWERBROADCAST",
	"PBT_APMPOWERSTATUSCHANGE",
	"PBT_APMRESUMEAUTOMATIC",
	"PBT_APMRESUMESUSPEND",
	"PBT_APMSUSPEND",
	"PBT_POWERSETTINGSCHANGE",
	"PBT_APMSTANDBY",
	"PBT_APMOEMEVENT",
	"PBT_APMBATTERYLOW",
	"PBT_APMQUERYSTANDBY",
	"PBT_APMQUERYSUSPEND",
	"PBT_APMRESUMESTANDBY",
	"PBT_APMRESUMECRITICAL",
	"PBT_APMQUERYSTANDBYFAILED",
	"PBT_APMQUERYSUSPENDFAILED"
]

OnMessage(WM_POWERBROADCAST, powerbroadcast)

/**
 * handles power broadcast messages
 * @param wParam the type of power broadcast (PBT_POWERSTATUSCHANGE...)
 * @param lParam if wParam is of type PBT_POWERSETTINGCHANGE, then this is a POWERBROADCAST_SETTING structure
 * @param msg the message
 * @param hwnd the window handle
 */
powerbroadcast(wParam, lParam, msg, hwnd) {
	global types
	; TODO on battery:
	; - add refresh rate to 60Hz
	; TODO add remaining constants
	switch wParam {
		case PBT_POWERSETTINGSCHANGE:
			powersetting := NumGet(0, "uint")
			OutputDebug("powersetting change")
		case PBT_APMPOWERSTATUSCHANGE:
			/** @type {PowerStatus} */
			status := GetSystemPowerStatus()
			if !status {
				Notification("could not fetch power status")
				return
			}

			if status.NoBattery || status.Unknown {
				Notification("no battery found after activation")
				ExitApp(1)
			}

			OutputDebug("power status change`n" .
				status.ACLineStatus . ' `n' .
				status.BatteryFlag . ' `n' .
				status.BatteryLifePercent . ' `n' .
				status.SystemStatusFlag . ' `n')
		default:
			for eventType in types {
				if %eventType% == wParam {
					OutputDebug("battery event " . eventType . "=" . lParam)
					return
				}
			}

			OutputDebug("unknown powerbroadcast: " . wParam . "=" . lParam)
	}
}

; startup check if there even is a battery

status := GetSystemPowerStatus()
if !status {
	Notification("could not fetch power status")
	ExitApp(0)
}

if status.NoBattery || status.Unknown {
	; quit if no battery is available
	ExitApp(0)
}

Persistent(true)