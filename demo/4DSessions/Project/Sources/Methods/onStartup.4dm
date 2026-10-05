//%attributes = {}
// ----------------------------------------------------
// User name (OS): Al Mahdi
// Date and time: 06/25/26, 12:45:11
// ----------------------------------------------------
// Method: onStartup
// Description
// Database startup method. Opens the StartScreen welcome form (non-blocking) in the
// application process, or brings it to the front if it is already open.
//
// Parameters
// None
// ----------------------------------------------------

#DECLARE($params : Object)

var $title : Text:=Localized string:C991("Start_WindowTitle")
var $window : Integer

If (Count parameters:C259=0)
	
	ARRAY LONGINT($windows; 0)
	WINDOW LIST($windows)
	
	var $i : Integer
	For ($i; 1; Size of array($windows))
		$window:=$windows{$i}
		If (Window process($window)=1) && (Get window title($window)=$title)
			var $left; $top; $right; $bottom : Integer
			GET WINDOW RECT($left; $top; $right; $bottom; $window)
			CALL FORM($window; Formula(SET WINDOW RECT($left; $top; $right; $bottom; $window)))
			return 
		End if 
	End for 
	
	CALL WORKER(1; Current method name:C684; {})
	
Else 
	
	SET MENU BAR(1)
	
	$window:=Open form window:C675("StartScreen"; Plain form window:K39:10; Horizontally centered; Vertically centered)
	SET WINDOW TITLE($title; $window)
	DIALOG:C40("StartScreen"; *)
	
End if 
