// ----------------------------------------------------
// User name (OS): Al Mahdi
// Date and time: 06/25/26, 12:45:11
// ----------------------------------------------------
// Method: Button
// Description
// Object method for the main action button in Session_Form. On click, retrieves
// the web server address and port, generates an OTP via getOTP, builds the /init
// URL, and prompts the operator to open it in a browser.
//
// Parameters
// None (form event driven)
// ----------------------------------------------------

If (Form event code:C388=On Clicked:K2:4)
	var $serverInfo : Object:=WEB Get server info:C1531
	var $port : Integer:=$serverInfo.options.webPortID
	var $host : Text:=$serverInfo.options.webIPAddressToListen[0]
	var $otp : Text:=getOTP

	// OTP is now created and the timer is running.
	// To test expiry: copy the URL below, wait past the limit, paste in an incognito window.
	var $url : Text
	If ($port=80)
		$url:="http://"+$host+"/init?$4DSID="+$otp
	Else
		$url:="http://"+$host+":"+String:C10($port)+"/init?$4DSID="+$otp
	End if
	CONFIRM:C162(Localized string:C991("Session_ConfirmOTP")+Char:C90(13)+$url; Localized string:C991("Session_OpenInBrowser"); Localized string:C991("CommonCancel"))

	If (ok=1)
		OPEN URL:C673($url)
	End if
End if