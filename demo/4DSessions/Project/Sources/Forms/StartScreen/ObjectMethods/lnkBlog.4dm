// ----------------------------------------------------
// User name (OS): Al Mahdi
// Date and time: 06/25/26, 12:45:11
// ----------------------------------------------------
// Method: lnkBlog
// Description
// Object method for the Blog link in StartScreen. On click, opens the
// 4D official blog in the system default browser.
//
// Parameters
// None (form event driven)
// ----------------------------------------------------


If (Form event code:C388=On Clicked:K2:4)
	OPEN URL:C673("https://blog.4d.com/")
End if 
