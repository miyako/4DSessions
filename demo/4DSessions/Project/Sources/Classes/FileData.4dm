
// ----------------------------------------------------
// User name (OS): Al Mahdi
// Date and time: 06/25/26, 12:45:11
// ----------------------------------------------------
// Class: FileData
// Description
// Data transfer class representing a single uploaded file.
// Stores the file name and its binary content as properties.
//
// Parameters
// None
// ----------------------------------------------------

property name : Text
property content : Blob


// ----------------------------------------------------
// User name (OS): Al Mahdi
// Date and time: 06/25/26, 12:45:11
// ----------------------------------------------------
// Method: Class constructor
// Description
// Initializes a FileData instance by assigning the provided file name
// and binary content to the corresponding properties.
//
// Parameters
// $fileName (Text) : The original name of the uploaded file
// $content  (Blob) : The binary content of the uploaded file
// ----------------------------------------------------
Class constructor($fileName : Text; $content : Blob)
	
	This:C1470.name:=$fileName
	This:C1470.content:=$content
	
	
	
	
	