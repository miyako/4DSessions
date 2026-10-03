// ----------------------------------------------------
// User name (OS): Al Mahdi
// Date and time: 06/25/26, 12:45:11
// ----------------------------------------------------
// Method: lnkDocs
// Description
// Object method for the Docs link in StartScreen. On click, opens the
// 4D Session class API reference in the system default browser.
//
// Parameters
// None (form event driven)
// ----------------------------------------------------

// Open the 4D Session class documentation in the default browser.

If (Form event code:C388=On Clicked:K2:4)
	OPEN URL:C673("https://developer.4d.com/docs/API/SessionClass")
End if
