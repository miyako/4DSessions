// ----------------------------------------------------
// User name (OS): Al Mahdi
// Date and time: 06/25/26, 12:45:11
// ----------------------------------------------------
// Method: BtnOpen
// Description
// Object method for the "Open Workspace" button in StartScreen. On click, checks
// that the web server is running and opens the Session_Form dialog. Displays an
// alert if the web server has not been started yet.
//
// Parameters
// None (form event driven)
// ----------------------------------------------------

If (Form event code:C388=On Clicked:K2:4)
	var $serverInfo : Object:=WEB Get server info:C1531
	If ($serverInfo.started)
		var $window : Integer:=Open form window:C675("Session_Form"; Plain form window:K39:10)
		DIALOG:C40("Session_Form")
		CLOSE WINDOW:C154($window)
	Else 
		ALERT:C41("The web server is not running. Please start it in the Runtime Explorer before launching the demo.")
	End if 
End if 