//%attributes = {"executedOnServer":true}

// ----------------------------------------------------
// User name (OS): Al Mahdi
// Date and time: 06/25/26, 12:45:11
// ----------------------------------------------------
// Method: getOTP
// Description
// Creates a new OTP session by storing a desktop message timestamp, initializing
// a fresh verification challenge, and returning a 5-character one-time password.
//
// Parameters
// None — returns Text (the generated OTP token)
// ----------------------------------------------------

#DECLARE : Text

Use (Session:C1714.storage)
	Session:C1714.storage.desktopMessage:=New shared object:C1526("openedAt"; Timestamp:C1445)
End use 

cs:C1710.GeneralHandling.new().newChallenge()
return Session:C1714.createOTP(20)
