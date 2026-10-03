
// ----------------------------------------------------
// User name (OS): Al Mahdi
// Date and time: 06/25/26, 12:45:11
// ----------------------------------------------------
// Class: HandleWebBodyParts
// Description
// Shared singleton class that parses a multipart/form-data HTTP request body.
// Collects all body parts into a structured object with file metadata and content.
//
// Parameters
// None
// ----------------------------------------------------

// ----------------------------------------------------
// User name (OS): Al Mahdi
// Date and time: 06/25/26, 12:45:11
// ----------------------------------------------------
// Method: Class constructor
// Description
// Initializes the HandleWebBodyParts shared singleton. No setup required.
//
// Parameters
// None
// ----------------------------------------------------
shared singleton Class constructor()


// ----------------------------------------------------
// User name (OS): Al Mahdi
// Date and time: 06/25/26, 12:45:11
// ----------------------------------------------------
// Method: handleWebBodyParts
// Description
// Iterates over all body parts in the current HTTP request using the 4D WEB
// commands and returns an object keyed by "file1", "file2", … Each value is a
// FileData instance (name + content). Also accumulates the total byte size in
// the "size" property.
//
// Parameters
// None — reads the active web request context implicitly
//
// Returns: Object — { file1: FileData, file2: FileData, …, size: Integer }
// ----------------------------------------------------
Function handleWebBodyParts() : Object
	
	var $i : Integer
	var $partContent : Blob
	var $partName; $partMimeType; $partFileName : Text
	var $result:={size: 0}
	var $file : cs:C1710.FileData
	
	
	For ($i; 1; WEB Get body part count:C1211)
		WEB GET BODY PART:C1212($i; $partContent; $partName; $partMimeType; $partFileName)
		$file:=cs:C1710.FileData.new($partFileName; $partContent)
		$result["file"+String:C10($i)]:=$file
		$result.size:=$result.size+BLOB size:C605($partContent)
	End for 
	
	return $result