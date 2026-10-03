
// ----------------------------------------------------
// User name (OS): Al Mahdi
// Date and time: 06/25/26, 12:45:11
// ----------------------------------------------------
// Class: FilesHandling
// Description
// Shared singleton class that handles HTTP file upload and download requests.
// Processes multipart form submissions and serves image or document files.
//
// Parameters
// None
// ----------------------------------------------------


shared singleton Class constructor()
	
	
	
	// ----------------------------------------------------
Function handleFiles($request : 4D:C1709.IncomingMessage) : Variant
	
	var $result : Variant
	var $file : 4D:C1709.File
	var $image; $thumbnail : Picture
	var $width; $height : Integer
	var $name; $type; $prop : Text
	var $parts : Object
	var $created : Boolean
	
	Case of 
			
		: ($request.urlPath.first()="fileUpload")
			
			$parts:=cs:C1710.HandleWebBodyParts.me.handleWebBodyParts()
			
			For each ($prop; $parts)
				If ($prop#"size")
					$file:=File:C1566("/PACKAGE/Files/"+$parts[$prop].name)
					$created:=$file.create()
					$file.setContent($parts[$prop].content)
				End if 
			End for each 
			
			$result:={status: String:C10(OB Entries:C1720($parts).length-1)+" files have been uploaded - Total size: "+String:C10($parts.size)+" bytes"}
			
			
		: ($request.urlPath.first()="fileDownload")
			
			$result:=4D:C1709.OutgoingMessage.new()
			
			$name:=$request.urlQuery.name
			$type:=$request.urlQuery.type
			$width:=Num:C11($request.urlQuery.width)
			$height:=Num:C11($request.urlQuery.height)
			
			Case of 
				: ($type="image")
					$file:=File:C1566("/RESOURCES/Images/Products/"+$name+".jpg")
					READ PICTURE FILE:C678($file.platformPath; $image)
					CREATE THUMBNAIL:C679($image; $thumbnail; $width; $height; Scaled to fit:K6:2)
					$result.setBody($thumbnail)
					$result.setHeader("Content-Type"; "image/jpeg")
					
				: ($type="userManual")
					$file:=File:C1566("/RESOURCES/User manuals/"+$name+".pdf")
					$result.setBody($file.getContent())
					$result.setHeader("Content-Type"; "application/pdf")
			End case 
			
	End case 
	
	return $result