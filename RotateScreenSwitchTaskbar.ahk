#NoEnv
#SingleInstance force
SetWorkingDir %A_ScriptDir%

#Include <dict>

TaskbarPos := new dict()
TaskbarPos.map(["left", "top", "right", "bottom"],["30000000FEFFFFFF7AF40000000000003C00000030","30000000FEFFFFFF7AF40000010000003C00000030","30000000FEFFFFFF7AF40000020000003C00000030","30000000FEFFFFFF7AF40000030000003C00000030"])

; Defining the variables in this script
SysGet, display, MonitorName
rotation:={1:0,2:1,3:2,4:3}

; Hotkey for Screen Orientation Switch
^!w::
	NewBinaryRegValue := sResult := cOri := ""
	sRes:=strSplit((screenRes_Get(display)),["x","@","-"])

	; Current orientation is landscape
	If((display) == "landscape") {
		; So we rotate to portrait mode now
		sResult := screenRes_Set(sRes[2] "x" sRes[1] "@" sRes[3], display, rotation[4])
		; Check if screen rotation was successfull and if taskbar is at the bottom of the screen
		If(Get_DisplayOrientation(display) == "portrait (gedreht)" && GetCurrentTaskbarPos() == "bottom") {
			; NewBinaryRegValue now contains the binary string for the registry for taskbar at the bottom
			NewBinaryRegValue := TaskbarPos.get("top") . CurrRegVal_p2
		}
	} ; Current orientation is portrait
	else If(Get_DisplayOrientation(display) == "portrait (gedreht)") {
		; So we rotate to landscape mode now
		sResult := screenRes_Set(sRes[2] "x" sRes[1] "@" sRes[3], display, rotation[1])
		; Check if screen rotation was successfull and if taskbar is at the top of the screen
		If(Get_DisplayOrientation(display) == "landscape" && GetCurrentTaskbarPos() == "top") {
			; NewBinaryRegValue now contains the binary string for the registry for taskbar at the top
			NewBinaryRegValue := TaskbarPos.get("bottom") . CurrRegVal_p2
		}
	}
	else
		sResult := "Could not retrieve the current screen orientation!`nFound: " Get_DisplayOrientation(display)

	If(NewBinaryRegValue) {
		RegWrite, REG_BINARY, HKCU, Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3, Settings, % NewBinaryRegValue
		If(!ErrorLevel)
			RefreshTaskbar()
		else
			msgbox, % "Something went terribly wrong!`nPlease check your registry on errors."
	}
Return

;https://www.autohotkey.com/boards/viewtopic.php?t=77664€
screenRes_Set(WxHaF, Disp:=0, orient:=0) {
	Local DM, N:=VarSetCapacity(DM,220,0), F:=StrSplit(WxHaF,["x","@"],A_Space)
	Return DllCall("ChangeDisplaySettingsExW",(Disp=0 ? "Ptr" : "WStr"),Disp,"Ptr",NumPut(F[3],NumPut(F[2],NumPut(F[1]
		,NumPut(32,NumPut(0x5C0080,NumPut(220,NumPut(orient,DM,84,"UInt")-20,"UShort")+2,"UInt")+92,"UInt"),"UInt")
		,"UInt")+4,"UInt")-188, "Ptr",0, "Int",0, "Int",0)  
}

screenRes_Get(Disp:=0) {
	Local DM, N:=VarSetCapacity(DM,220,0) 
	Return DllCall("EnumDisplaySettingsW", (Disp=0 ? "Ptr" : "WStr"),Disp, "Int",-1, "Ptr",&DM)=0 ? ""
		: Format("{:}x{:}@{:}-{:}", NumGet(DM,172,"UInt"),NumGet(DM,176,"UInt"),NumGet(DM,184,"UInt"),NumGet(DM,84,"WStr")) 
}

GetCurrentTaskbarPos() {
;Windows11 Taskbar Location (registry binary value)
;	Path: HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3
;	Key	: Settings
	Global
	RegRead, StuckRects3, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3, Settings
	CurrRegVal_p1 := SubStr(StuckRects3, 1, 42), CurrRegVal_p2 := SubStr(StuckRects3, 43)
	for k, v in TaskbarPos.data
		if(v == CurrRegVal_p1)
			Return, % k
}

RefreshTaskbar() {
	If(A_IsAdmin) {
		return, % SilentRun("PowerShell.exe -Command kill -n explorer")
	}
	return False
}

SilentRun(cmd) {
    exec := ComObjCreate("WScript.Shell").Exec(ComSpec " /c " cmd)
    return, % exec.StdOut.ReadAll()
}
