//%attributes = {}
// ----------------------------------------------------
// User name (OS): Al Mahdi
// Date and time: 06/25/26, 12:45:11
// ----------------------------------------------------
// Method: onStartup
// Description
// Database startup method. Opens the StartScreen welcome form in a plain window
// and closes it when the user dismisses it.
//
// Parameters
// None
// ----------------------------------------------------

#DECLARE($OK : Integer)
If (Count parameters:C259=0)
	BRING TO FRONT:C326(New process:C317(Current method name:C684; 0; "Demo"; 1; *))
Else 
	var $window : Integer:=Open form window:C675("StartScreen"; Plain form window:K39:10)
	DIALOG:C40("StartScreen")
	CLOSE WINDOW:C154($window)
End if 

