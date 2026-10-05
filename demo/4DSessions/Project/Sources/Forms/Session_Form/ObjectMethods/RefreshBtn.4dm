// ----------------------------------------------------
// User name (OS): Al Mahdi
// Date and time: 06/25/26, 12:45:11
// ----------------------------------------------------
// Method: RefreshBtn
// Description
// Object method for the Refresh button in Session_Form. On click, re-reads the
// web server info and the current session to refresh all displayed fields
// (type, user, machine, IP, session ID, creation time, and footer timestamp).
//
// Parameters
// None (form event driven)
// ----------------------------------------------------

If (Form event code:C388=On Clicked:K2:4)
	var $si : Object:=WEB Get server info:C1531
	var $ip : Text:=$si.options.webIPAddressToListen[0]
	var $port : Integer:=$si.options.webPortID
	If (($ip="0.0.0.0") | ($ip=""))
		$ip:="localhost"
	End if
	var $serverDisplay : Text
	If ($port=80)
		$serverDisplay:=$ip
	Else
		$serverDisplay:=$ip+":"+String:C10($port)
	End if

	OBJECT SET TITLE(* ; "valType"; Session:C1714.type)
	OBJECT SET TITLE(* ; "valUser"; Current user)
	OBJECT SET TITLE(* ; "valMachine"; Get environment variable("COMPUTERNAME"))
	OBJECT SET TITLE(* ; "valIP"; $serverDisplay)

	var $sid : Text:=Session:C1714.id
	OBJECT SET TITLE(* ; "valSID"; Uppercase:C13(Substring:C12($sid; 1; 8))+"…"+Uppercase:C13(Substring:C12($sid; Length:C16($sid)-5; 6)))
	OBJECT SET TITLE(* ; "valCreated"; Substring:C12(Timestamp:C1445; 1; 16)+" UTC")

	OBJECT SET TITLE(* ; "footerTxt"; Replace string:C233(Localized string:C991("Session_LastRefreshed"); "{time}"; Substring:C12(Timestamp:C1445; 12; 5)))
End if
