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
		// Non-blocking: the start screen stays open; reuse the session window if it is already open
		var $title : Text:=Localized string:C991("Session_WindowTitle")
		ARRAY LONGINT($windows; 0)
		WINDOW LIST($windows)
		var $i; $window : Integer
		For ($i; 1; Size of array($windows))
			$window:=$windows{$i}
			If (Window process($window)=Current process) && (Get window title($window)=$title)
				var $left; $top; $right; $bottom : Integer
				GET WINDOW RECT($left; $top; $right; $bottom; $window)
				SET WINDOW RECT($left; $top; $right; $bottom; $window)
				return 
			End if 
		End for 
		$window:=Open form window:C675("Session_Form"; Plain form window:K39:10; Horizontally centered; Vertically centered)
		DIALOG:C40("Session_Form"; *)
	Else 
		ALERT:C41(Localized string:C991("Start_AlertWebServerOff"))
	End if 
End if 