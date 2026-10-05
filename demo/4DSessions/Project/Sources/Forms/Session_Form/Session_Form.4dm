// ----------------------------------------------------
// User name (OS): Al Mahdi
// Date and time: 06/25/26, 12:45:11
// ----------------------------------------------------
// Method: Session_Form
// Description
// Form method for the Session_Form dialog. Handles the On Load event by reading
// the current session info and populating the UI label fields with type, user,
// machine, IP address, session ID, and creation time.
//
// Parameters
// None (form event driven)
// ----------------------------------------------------

Case of
	: (Form event code:C388=On Load:K2:1)
		var $info : Object:=Session:C1714.info

		OBJECT SET TITLE(* ; "valType"; String:C10($info.type))
		OBJECT SET TITLE(* ; "valUser"; String:C10($info.userName))
		OBJECT SET TITLE(* ; "valMachine"; String:C10($info.machineName))
		OBJECT SET TITLE(* ; "valIP"; String:C10($info.IPAddress))

		var $id : Text:=String:C10($info.ID)
		If (Length:C16($id)>12)
			OBJECT SET TITLE(* ; "valSID"; Uppercase:C13(Substring:C12($id; 1; 8))+"…"+Uppercase:C13(Substring:C12($id; Length:C16($id)-5; 6)))
		Else
			OBJECT SET TITLE(* ; "valSID"; $id)
		End if

		var $dt : Text:=String:C10($info.creationDateTime)
		$dt:=Replace string:C233($dt; "T"; " ")
		OBJECT SET TITLE(* ; "valCreated"; Substring:C12($dt; 1; 16))
		OBJECT SET TITLE(* ; "statePillTxt"; Localized string:C991("Session_Active"))
End case
