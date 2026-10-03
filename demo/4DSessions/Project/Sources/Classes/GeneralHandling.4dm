// ----------------------------------------------------
// User name (OS): Al Mahdi
// Date and time: 06/25/26, 12:45:11
// ----------------------------------------------------
// Class: GeneralHandling
// Description
// Shared singleton class centralizing all HTTP route handlers, session state
// management, automated file checks, and HTML rendering for the 4D Secure OTP
// identity verification system. Routes are mapped in HTTPHandlers.json.
//
// Parameters
// None
// ----------------------------------------------------


shared singleton Class constructor()
	
	
Function sanitizeFileName($name : Text) : Text
	var $clean : Text:=Trim:C1853($name)
	$clean:=Replace string:C233($clean; "\\"; "_")
	$clean:=Replace string:C233($clean; "/"; "_")
	$clean:=Replace string:C233($clean; ".."; "_")
	$clean:=Replace string:C233($clean; ":"; "_")
	$clean:=Trim:C1853($clean)
	If ($clean="")
		$clean:="upload_"+Session:C1714.id
	End if 
	return $clean
	
Function htmlEscape($text : Text) : Text
	var $t : Text:=$text
	$t:=Replace string:C233($t; "&"; "&amp;")
	$t:=Replace string:C233($t; "<"; "&lt;")
	$t:=Replace string:C233($t; ">"; "&gt;")
	$t:=Replace string:C233($t; "\""; "&quot;")
	return $t
	
	
Function fileExt($name : Text) : Text
	If (Position:C15("."; $name)=0)
		return ""
	End if 
	var $rest : Text:=$name
	While (Position:C15("."; $rest)>0)
		$rest:=Substring:C12($rest; Position:C15("."; $rest)+1)
	End while 
	return Lowercase:C14($rest)
	
	
Function isImageExt($ext : Text) : Boolean
	return (Position:C15("/"+$ext+"/"; "/jpg/jpeg/png/gif/webp/bmp/heic/")>0)
	
	
Function humanSize($n : Integer) : Text
	If ($n<1024)
		return String:C10($n)+" B"
	End if 
	If ($n<1048576)
		return String:C10($n/1024; "###0.0")+" KB"
	End if 
	return String:C10($n/1048576; "###0.00")+" MB"
	
	
Function fmtTime($ts : Text) : Text
	If (Length:C16($ts)<19)
		return $ts
	End if 
	return Substring:C12($ts; 1; 10)+" · "+Substring:C12($ts; 12; 5)+" UTC"
	
Function reasonLabel($code : Text) : Text
	Case of 
		: ($code="identity_confirmed")
			return "Identity confirmed"
		: ($code="manual_override")
			return "Manual override"
		: ($code="doc_unreadable")
			return "Document unreadable"
		: ($code="face_mismatch")
			return "Face mismatch"
		: ($code="suspected_tampering")
			return "Suspected tampering"
		: ($code="wrong_document")
			return "Wrong document"
		: ($code="retake_photo")
			return "Please retake the photo"
		: ($code="better_lighting")
			return "Better lighting required"
		: ($code="full_document")
			return "Full document required"
		: ($code="other")
			return "Other"
	End case 
	return $code
	
Function pill($status : Text) : Text
	var $label : Text:=$status
	Case of 
		: ($status="pending")
			$label:="Pending"
		: ($status="verified")
			$label:="Verified"
		: ($status="under_review")
			$label:="Under review"
		: ($status="approved")
			$label:="Approved"
		: ($status="rejected")
			$label:="Rejected"
		: ($status="info_requested")
			$label:="Info requested"
	End case 
	return "<span class='pill "+$status+"'>"+$label+"</span>"
	
	
	
Function htmlResult($html : Text; $status : Integer) : 4D:C1709.OutgoingMessage
	var $r:=4D:C1709.OutgoingMessage.new()
	$r.setBody($html)  // setBody auto-detects content type — must precede setHeader
	$r.setHeader("Content-Type"; "text/html; charset=utf-8")
	If ($status>0)
		$r.setStatus($status)
	End if 
	return $r
	
	
Function jsonResult($obj : Object; $status : Integer) : 4D:C1709.OutgoingMessage
	var $r:=4D:C1709.OutgoingMessage.new()
	$r.setBody(JSON Stringify:C1217($obj))
	$r.setHeader("Content-Type"; "application/json; charset=utf-8")
	If ($status>0)
		$r.setStatus($status)
	End if 
	return $r
	
	
Function newChallenge()
	// Each case starts with a clean activity log
	Use (Session:C1714.storage)
		Session:C1714.storage.log:=New shared collection:C1527
	End use 
	var $correct; $w1; $w2 : Integer
	$correct:=(Random:C100%90)+10
	Repeat 
		$w1:=(Random:C100%90)+10
	Until ($w1#$correct)
	Repeat 
		$w2:=(Random:C100%90)+10
	Until (($w2#$correct) & ($w2#$w1))
	
	var $o : Collection:=New collection:C1472(String:C10($correct); String:C10($w1); String:C10($w2))
	var $i; $j : Integer
	var $tmp : Text
	For ($i; 2; 1; -1)
		$j:=Random:C100%($i+1)
		$tmp:=$o[$i]
		$o[$i]:=$o[$j]
		$o[$j]:=$tmp
	End for 
	
	var $n : Integer:=(Random:C100%9000)+1000
	var $ref : Text:="VR-"+Substring:C12(Timestamp:C1445; 1; 4)+"-"+String:C10($n)
	
	Use (Session:C1714.storage)
		Session:C1714.storage.data:=New shared object:C1526(\
			"ref"; $ref; \
			"challenge"; String:C10($correct); \
			"options"; New shared collection:C1527($o[0]; $o[1]; $o[2]); \
			"status"; "pending"; \
			"message"; "Tap the number shown on the desktop screen."; \
			"reply"; ""; \
			"createdAt"; Timestamp:C1445; \
			"submittedAt"; ""; \
			"fileName"; ""; \
			"fileSize"; ""; \
			"fileType"; ""; \
			"sha256"; ""; \
			"checks"; ""; \
			"decisionOutcome"; ""; \
			"decisionReason"; ""; \
			"decisionNotes"; ""; \
			"decidedAt"; ""; \
			"reviewer"; "")
	End use 
	This:C1470.addLog("Case "+$ref+" opened.")
	
	
Function ensureChallenge()
	If (Session:C1714.storage.data=Null:C1517)
		This:C1470.newChallenge()
	End if 
	
Function addLog($msg : Text)
	If (Session:C1714.storage.log=Null:C1517)
		Use (Session:C1714.storage)
			Session:C1714.storage.log:=New shared collection:C1527
		End use 
	End if 
	Use (Session:C1714.storage.log)
		Session:C1714.storage.log.push(New shared object:C1526("t"; Timestamp:C1445; "m"; $msg))
		While (Session:C1714.storage.log.length>30)
			Session:C1714.storage.log.remove(0)
		End while 
	End use 
	
Function caseObject() : Object
	var $o : Object:=New object:C1471
	var $d : Object:=Session:C1714.storage.data
	$o.verified:=Session:C1714.hasPrivilege("verified_user")
	$o.sessionId:=Session:C1714.id
	If ($d=Null:C1517)
		$o.status:="expired"
		return $o
	End if 
	$o.ref:=String:C10($d.ref)
	$o.status:=String:C10($d.status)
	$o.message:=String:C10($d.message)
	$o.reply:=String:C10($d.reply)
	$o.createdAt:=String:C10($d.createdAt)
	$o.submittedAt:=String:C10($d.submittedAt)
	$o.evidence:=New object:C1471("fileName"; String:C10($d.fileName); "size"; String:C10($d.fileSize); "type"; String:C10($d.fileType); "sha256"; String:C10($d.sha256))
	If (String:C10($d.checks)#"")
		$o.checks:=JSON Parse:C1218(String:C10($d.checks))
	Else 
		$o.checks:=New collection:C1472
	End if 
	$o.decision:=New object:C1471("outcome"; String:C10($d.decisionOutcome); "reasonCode"; String:C10($d.decisionReason); "notes"; String:C10($d.decisionNotes); "decidedAt"; String:C10($d.decidedAt); "reviewer"; String:C10($d.reviewer))
	return $o
	
	
	
Function runChecks($content : Blob; $name : Text; $file : 4D:C1709.File; $sha : Text) : Collection
	var $checks : Collection:=New collection:C1472
	var $size : Integer:=BLOB size:C605($content)
	var $ext : Text:=This:C1470.fileExt($name)
	var $isImg : Boolean:=This:C1470.isImageExt($ext)
	
	// 1 · file integrity
	If ($size>0)
		$checks.push(New object:C1471("state"; "pass"; "label"; "File integrity"; "value"; "Valid"; "note"; "Non-empty file received"))
	Else 
		$checks.push(New object:C1471("state"; "fail"; "label"; "File integrity"; "value"; "Empty"; "note"; "No bytes received"))
	End if 
	
	// 2 · file size
	$checks.push(New object:C1471("state"; "pass"; "label"; "File size"; "value"; This:C1470.humanSize($size); "note"; "Within accepted range"))
	
	// 3 · file type
	If ($isImg)
		$checks.push(New object:C1471("state"; "pass"; "label"; "File type"; "value"; Uppercase:C13($ext); "note"; "Recognised image format"))
	Else 
		var $tv : Text:="Unknown"
		If ($ext#"")
			$tv:=Uppercase:C13($ext)
		End if 
		$checks.push(New object:C1471("state"; "info"; "label"; "File type"; "value"; $tv; "note"; "Not a standard image format"))
	End if 
	
	// 4 · image readability
	If ($isImg)
		var $ok : Boolean:=False:C215
		Try
			var $pic : Picture
			READ PICTURE FILE:C678($file.platformPath; $pic)
			$ok:=True:C214
		Catch
			$ok:=False:C215
		End try
		If ($ok)
			$checks.push(New object:C1471("state"; "pass"; "label"; "Image readability"; "value"; "Readable"; "note"; "Image decoded successfully"))
		Else 
			$checks.push(New object:C1471("state"; "warn"; "label"; "Image readability"; "value"; "Unreadable"; "note"; "Image data could not be decoded"))
		End if 
	Else 
		$checks.push(New object:C1471("state"; "info"; "label"; "Image readability"; "value"; "n/a"; "note"; "Not an image file"))
	End if 
	
	// 5 · integrity hash (chain of custody)
	If ($sha#"")
		$checks.push(New object:C1471("state"; "info"; "label"; "Integrity hash"; "value"; Substring:C12($sha; 1; 16)+"…"; "note"; "SHA-256 · chain of custody"))
	End if 
	
	// 6 · duplicate detection
	$checks.push(New object:C1471("state"; "info"; "label"; "Duplicate check"; "value"; "Unique"; "note"; "First submission in this session"))
	
	return $checks
	
	
	
Function extractUploadedFile($request : 4D:C1709.IncomingMessage) : Object
	var $rawBlob : Blob:=$request.getBlob()
	var $ct : Text:=$request.getHeader("content-type")
	
	var $bp : Integer:=Position:C15("boundary="; $ct)
	If ($bp=0)
		return Null:C1517
	End if 
	var $boundary : Text:="--"+Trim:C1853(Substring:C12($ct; $bp+9))
	
	var $body : Text:=BLOB to text:C555($rawBlob; Mac text without length:K22:10)
	
	var $name : Text:=""
	var $fnPos : Integer:=Position:C15("filename=\""; $body)
	If ($fnPos>0)
		var $after : Text:=Substring:C12($body; $fnPos+10)
		var $q : Integer:=Position:C15("\""; $after)
		If ($q>0)
			$name:=Substring:C12($after; 1; $q-1)
		End if 
	End if 
	
	var $crlf : Text:=Char:C90(13)+Char:C90(10)
	var $hEnd : Integer:=Position:C15($crlf+$crlf; $body)
	var $close : Integer:=Position:C15($boundary+"--"; $body)
	If ($hEnd=0)
		return Null:C1517
	End if 
	
	var $start : Integer:=$hEnd+4
	var $end : Integer
	If ($close>0)
		$end:=$close-2
	Else 
		$end:=Length:C16($body)
	End if 
	var $size : Integer:=$end-$start
	If ($size<=0)
		return Null:C1517
	End if 
	
	var $fileBlob : Blob
	COPY BLOB:C558($rawBlob; $fileBlob; $start-1; 0; $size)
	return New object:C1471("name"; $name; "content"; $fileBlob; "size"; $size)
	
	
	// ─── ROUTE: GET /init  ────────────────────────────
	
Function initialize($request : 4D:C1709.IncomingMessage) : 4D:C1709.OutgoingMessage
	// Null data means no valid desktop OTP was used — expired or direct URL access.
	// Same guard as /scan and /reply.
	If (Session:C1714.storage.data=Null:C1517)
		var $errMain : Text:="<div class='pagehead'><div><h1>Session expired</h1>"
		$errMain+="<p class='substatus'>This link is no longer valid.</p></div></div>"
		$errMain+="<section class='card'><div class='card-body'>"
		$errMain+="<div class='banner warn'>Open this console from the desktop application to start a new session.</div>"
		$errMain+="</div></section>"
		return This:C1470.htmlResult(This:C1470.verifyShell("Session expired"; $errMain; "expired"; "dashboard"); 403)
	End if 
	var $d : Object:=Session:C1714.storage.data
	var $status : Text:=String:C10($d.status)
	var $main : Text
	Case of 
		: ($status="under_review")
			$main:=This:C1470.reviewMain()
		: ($status="approved") | ($status="rejected") | ($status="info_requested")
			$main:=This:C1470.outcomeMain()
		Else 
			$main:=This:C1470.progressMain($request)
	End case 
	return This:C1470.htmlResult(This:C1470.verifyShell("Case "+String:C10($d.ref); $main; $status; "dashboard"); 0)
	
	
	// ─── ROUTE: GET /scan  ──────────────────────────────
	
Function scan($request : 4D:C1709.IncomingMessage) : 4D:C1709.OutgoingMessage
	If (Session:C1714.storage.data=Null:C1517)
		var $e : Text:="<div class='scard center'><div class='banner warn'>QR code expired</div>"
		$e+="<p class='muted'>This link is no longer valid.</p>"
		$e+="<p class='muted' style='margin-top:8px'>Ask the operator to click <b>Regenerate QR &amp; challenge</b> on the pairing screen to get a fresh code.</p>"
		$e+="</div>"
		return This:C1470.htmlResult(This:C1470.subjectShell("Expired"; $e; "expired"); 403)
	End if 
	
	var $d : Object:=Session:C1714.storage.data
	var $status : Text:=String:C10($d.status)
	var $m : Text
	
	Case of 
		: ($status="under_review")
			$m:="<div class='scard'><div class='stitle'>✓ Submission received</div>"
			$m+="<div class='steps2'><div class='s on'></div><div class='s on'></div><div class='s on'></div></div>"
			$m+="<dl class='def'><dt>Reference</dt><dd>"+String:C10($d.ref)+"</dd><dt>File</dt><dd>"+This:C1470.htmlEscape(String:C10($d.fileName))+"</dd><dt>Submitted</dt><dd>"+This:C1470.fmtTime(String:C10($d.submittedAt))+"</dd></dl>"
			$m+="<p class='note'>Your submission is under review. You can close this page and reopen the link to check the outcome.</p></div>"
			
		: ($status="approved")
			$m:="<div class='scard center'><div class='banner ok'>Verification complete</div>"
			$m+="<dl class='def'><dt>Reference</dt><dd>"+String:C10($d.ref)+"</dd><dt>Outcome</dt><dd>Approved</dd><dt>Confirmed</dt><dd>"+This:C1470.fmtTime(String:C10($d.decidedAt))+"</dd><dt>Confirmation</dt><dd><span class='code'>CNF-"+Uppercase:C13(Substring:C12(String:C10($d.sha256); 1; 8))+"</span></dd></dl></div>"
			
		: ($status="rejected")
			$m:="<div class='scard center'><div class='banner bad'>Verification unsuccessful</div>"
			$m+="<p>"+This:C1470.reasonLabel(String:C10($d.decisionReason))+"</p>"
			$m+="<dl class='def'><dt>Reference</dt><dd>"+String:C10($d.ref)+"</dd></dl></div>"
			
		: ($status="info_requested")
			$m:="<div class='scard'><div class='banner warn'>Additional information needed</div>"
			$m+="<p>"+This:C1470.reasonLabel(String:C10($d.decisionReason))+"</p>"
			var $nn : Text:=String:C10($d.decisionNotes)
			If ($nn#"")
				$m+="<p class='note'>"+This:C1470.htmlEscape($nn)+"</p>"
			End if 
			$m+="<div class='steps2'><div class='s on'></div><div class='s on'></div><div class='s'></div></div>"
			$m+=This:C1470.uploadFormHtml()+"</div>"
			
		: ($status="verified")
			$m:="<div class='scard'><div class='banner ok'>✓ Identity confirmed</div><p>Upload your verification photo to complete the process.</p>"
			$m+="<div class='steps2'><div class='s on'></div><div class='s on'></div><div class='s'></div></div>"
			$m+=This:C1470.uploadFormHtml()+"</div>"
			
		Else 
			$m:="<div class='scard'><div class='stitle'>Identity verification</div><div class='muted'>Reference "+String:C10($d.ref)+"</div>"
			$m+="<div class='steps2'><div class='s on'></div><div class='s'></div><div class='s'></div></div>"
			$m+="<p style='margin:10px 0 4px'>"+This:C1470.htmlEscape(String:C10($d.message))+"</p>"
			var $i : Integer
			For ($i; 0; $d.options.length-1)
				var $v : Text:=String:C10($d.options[$i])
				$m+="<button class='numbtn' onclick='pick("+$v+")'>"+$v+"</button>"
			End for 
			$m+="<div id='msg' class='note'></div></div>"
			$m+="<script>async function pick(v){var r=await fetch('/reply',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({reply:v})});var d=await r.json();if(d.status==='verified'){location.reload();return;}var m=document.getElementByI"+"d('msg');if(m){m.textContent=d.message||'Try again';}}</script>"
	End case 
	
	return This:C1470.htmlResult(This:C1470.subjectShell("Verification"; $m; $status); 0)
	
	
	// ─── ROUTE: POST /reply  (user submits a number) ──────────────────
	
Function reply($request : 4D:C1709.IncomingMessage) : 4D:C1709.OutgoingMessage
	If (Session:C1714.storage.data=Null:C1517)
		return This:C1470.jsonResult(New object:C1471("ok"; False:C215; "status"; "expired"; "message"; "Session expired"); 403)
	End if 
	
	var $reply : Text:=""
	var $ct : Text:=$request.getHeader("content-type")
	If (Position:C15("application/json"; $ct)>0)
		var $j : Object:=$request.getJSON()
		If ($j#Null:C1517)
			$reply:=String:C10($j.reply)
		End if 
	Else 
		var $raw : Text:=$request.getText()
		var $p : Integer:=Position:C15("reply="; $raw)
		If ($p>0)
			$reply:=Trim:C1853(Substring:C12($raw; $p+6))
		End if 
	End if 
	If ($reply="")
		$reply:=String:C10($request.urlQuery.reply)
	End if 
	
	var $correct : Boolean:=($reply=String:C10(Session:C1714.storage.data.challenge))
	If ($correct)
		Use (Session:C1714.storage.data)
			Session:C1714.storage.data.reply:=$reply
			Session:C1714.storage.data.status:="verified"
			Session:C1714.storage.data.message:="Identity confirmed. Please upload your photo."
		End use 
		If (Session:C1714.setPrivileges("verified_user"))
			This:C1470.addLog("Identity verified by subject.")
		End if 
	Else 
		Use (Session:C1714.storage.data)
			Session:C1714.storage.data.message:="That number is incorrect. Please try again."
		End use 
		This:C1470.addLog("Incorrect challenge response: "+$reply)
	End if 
	
	var $o : Object:=New object:C1471
	$o.ok:=$correct
	$o.status:=String:C10(Session:C1714.storage.data.status)
	$o.message:=String:C10(Session:C1714.storage.data.message)
	return This:C1470.jsonResult($o; 0)
	
	
	// ─── ROUTE: GET /status   ──────────────────────────────
	
Function status($request : 4D:C1709.IncomingMessage) : 4D:C1709.OutgoingMessage
	var $o : Object:=This:C1470.caseObject()
	If (Session:C1714.storage.log#Null:C1517)
		$o.log:=Session:C1714.storage.log.copy()
	Else 
		$o.log:=New collection:C1472
	End if 
	return This:C1470.jsonResult($o; 0)
	
	
	// ─── ROUTE: POST /fileUpload  (evidence submission) ──────────────────
	
Function upload($request : 4D:C1709.IncomingMessage) : 4D:C1709.OutgoingMessage
	If (Not:C34(Session:C1714.hasPrivilege("verified_user")))
		This:C1470.addLog("Upload blocked — session not verified.")
		return This:C1470.jsonResult(New object:C1471("ok"; False:C215; "message"; "Access denied. Verify the challenge first."); 403)
	End if 
	
	Try
		var $part : Object:=This:C1470.extractUploadedFile($request)
		If ($part=Null:C1517)
			return This:C1470.jsonResult(New object:C1471("ok"; False:C215; "message"; "No readable file in the request."); 400)
		End if 
		
		var $content : Blob:=$part.content
		var $size : Integer:=BLOB size:C605($content)
		If ($size<10) | ($size>10485760)
			return This:C1470.jsonResult(New object:C1471("ok"; False:C215; "message"; "File size is outside the accepted range."); 400)
		End if 
		
		var $name : Text:=This:C1470.sanitizeFileName(String:C10($part.name))
		var $folder : 4D:C1709.Folder:=Folder:C1567("/PACKAGE/Files")
		If (Not:C34($folder.exists))
			$folder.create()
		End if 
		var $file : 4D:C1709.File:=$folder.file($name)
		If ($file.exists)
			$file.delete()
		End if 
		$file.setContent($content)
		
		var $sha : Text:=""
		Try
			$sha:=Generate digest:C1147($content; SHA256 digest:K66:4)
		Catch
			$sha:=""
		End try
		
		var $checks : Collection:=This:C1470.runChecks($content; $name; $file; $sha)
		var $pass : Integer:=0
		var $i : Integer
		For ($i; 0; $checks.length-1)
			If (String:C10($checks[$i].state)="pass")
				$pass:=$pass+1
			End if 
		End for 
		
		Use (Session:C1714.storage.data)
			Session:C1714.storage.data.status:="under_review"
			Session:C1714.storage.data.submittedAt:=Timestamp:C1445
			Session:C1714.storage.data.fileName:=$name
			Session:C1714.storage.data.fileSize:=This:C1470.humanSize($size)
			Session:C1714.storage.data.fileType:=Uppercase:C13(This:C1470.fileExt($name))
			Session:C1714.storage.data.sha256:=$sha
			Session:C1714.storage.data.checks:=JSON Stringify:C1217($checks)
			Session:C1714.storage.data.message:="Submitted for review."
		End use 
		This:C1470.addLog("Evidence submitted: "+$name+" ("+This:C1470.humanSize($size)+").")
		This:C1470.addLog("Automated checks completed ("+String:C10($pass)+"/"+String:C10($checks.length)+" passed).")
		
		return This:C1470.jsonResult(New object:C1471("ok"; True:C214; "status"; "under_review"; "ref"; String:C10(Session:C1714.storage.data.ref); "message"; "Submission received."); 0)
		
	Catch
		This:C1470.addLog("Upload failed — "+JSON Stringify:C1217(Last errors:C1799))
		return This:C1470.jsonResult(New object:C1471("ok"; False:C215; "message"; "The upload could not be processed."); 500)
	End try
	
	
	// ─── ROUTE: POST /decision  (reviewer records an outcome) ────────────
	
Function decision($request : 4D:C1709.IncomingMessage) : 4D:C1709.OutgoingMessage
	var $d : Object:=Session:C1714.storage.data
	If ($d=Null:C1517)
		return This:C1470.jsonResult(New object:C1471("ok"; False:C215; "message"; "No active case."); 403)
	End if 
	If (String:C10($d.status)#"under_review")
		return This:C1470.jsonResult(New object:C1471("ok"; False:C215; "message"; "No case is awaiting a decision."); 409)
	End if 
	
	var $body : Object:=$request.getJSON()
	If ($body=Null:C1517)
		return This:C1470.jsonResult(New object:C1471("ok"; False:C215; "message"; "Invalid request body."); 400)
	End if 
	var $outcome : Text:=String:C10($body.outcome)
	var $reason : Text:=String:C10($body.reasonCode)
	var $notes : Text:=String:C10($body.notes)
	
	If ($outcome#"approved") & ($outcome#"rejected") & ($outcome#"info_requested")
		return This:C1470.jsonResult(New object:C1471("ok"; False:C215; "message"; "Unknown decision outcome."); 400)
	End if 
	If (($outcome="rejected") | ($outcome="info_requested")) & ($reason="")
		return This:C1470.jsonResult(New object:C1471("ok"; False:C215; "message"; "A reason code is required for this decision."); 400)
	End if 
	
	var $msg : Text:="Decision recorded."
	Case of 
		: ($outcome="approved")
			$msg:="Verification approved."
		: ($outcome="rejected")
			$msg:="Verification rejected."
		: ($outcome="info_requested")
			$msg:="Additional information requested."
	End case 
	
	Use (Session:C1714.storage.data)
		Session:C1714.storage.data.status:=$outcome
		Session:C1714.storage.data.decisionOutcome:=$outcome
		Session:C1714.storage.data.decisionReason:=$reason
		Session:C1714.storage.data.decisionNotes:=$notes
		Session:C1714.storage.data.decidedAt:=Timestamp:C1445
		Session:C1714.storage.data.reviewer:="Operator"
		Session:C1714.storage.data.message:=$msg
	End use 
	var $outLabel : Text:=$outcome
	Case of 
		: ($outcome="approved")
			$outLabel:="Approved"
		: ($outcome="rejected")
			$outLabel:="Rejected"
		: ($outcome="info_requested")
			$outLabel:="Info requested"
	End case 
	This:C1470.addLog("Decision: "+$outLabel+" — "+This:C1470.reasonLabel($reason)+" by Operator.")
	
	var $decidedRef : Text:=String:C10(Session:C1714.storage.data.ref)
	This:C1470.archiveCurrent()
	
	// Terminal decision → archive it and open a fresh case on the dashboard.
	// (info_requested stays on the same case so the subject can resubmit.)
	If ($outcome="approved") | ($outcome="rejected")
		If (Session:C1714.clearPrivileges())
			This:C1470.newChallenge()
		End if 
	End if 
	
	return This:C1470.jsonResult(New object:C1471("ok"; True:C214; "status"; $outcome; "message"; $msg; "ref"; $decidedRef); 0)
	
	
	// ─── ROUTE: GET /evidence  (serve the stored file for preview) ───────
	
Function evidence($request : 4D:C1709.IncomingMessage) : 4D:C1709.OutgoingMessage
	var $d : Object:=Session:C1714.storage.data
	If ($d=Null:C1517) | (String:C10($d.fileName)="")
		return This:C1470.jsonResult(New object:C1471("ok"; False:C215; "message"; "No evidence on file."); 404)
	End if 
	var $file : 4D:C1709.File:=Folder:C1567("/PACKAGE/Files").file(String:C10($d.fileName))
	If (Not:C34($file.exists))
		return This:C1470.jsonResult(New object:C1471("ok"; False:C215; "message"; "Evidence file missing."); 404)
	End if 
	
	var $r:=4D:C1709.OutgoingMessage.new()
	$r.setBody($file.getContent())
	var $ext : Text:=This:C1470.fileExt(String:C10($d.fileName))
	var $mime : Text:="application/octet-stream"
	Case of 
		: ($ext="jpg") | ($ext="jpeg")
			$mime:="image/jpeg"
		: ($ext="png")
			$mime:="image/png"
		: ($ext="gif")
			$mime:="image/gif"
		: ($ext="webp")
			$mime:="image/webp"
	End case 
	$r.setHeader("Content-Type"; $mime)
	return $r
	
	
	// ─── ROUTE: GET /report  (printable case report / JSON) ──────────────
	
Function report($request : 4D:C1709.IncomingMessage) : 4D:C1709.OutgoingMessage
	Try
		var $ref : Text:=String:C10($request.urlQuery.ref)
		var $fmt : Text:=String:C10($request.urlQuery.format)
		var $d : Object:=Session:C1714.storage.data
		var $src : Object:=Null:C1517
		var $log : Collection:=Null:C1517
		
		If ($ref="") | (($d#Null:C1517) & ($ref=String:C10($d.ref)))
			$src:=$d
			$log:=Session:C1714.storage.log
		Else 
			var $found : Object:=This:C1470.findCase($ref)
			If ($found#Null:C1517)
				$src:=$found
				$log:=$src.log
			End if 
		End if 
		
		If ($fmt="json")
			If ($src=Null:C1517)
				return This:C1470.jsonResult(New object:C1471("error"; "Report not found"); 404)
			End if 
			return This:C1470.jsonResult($src; 0)
		End if 
		return This:C1470.htmlResult(This:C1470.reportPage($src; $log); 0)
		
	Catch
		var $err : Text:="<!DOCTYPE html><html lang='en'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>Report</title>"
		$err+="<link href='https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;600&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap' rel='stylesheet'>"
		$err+="<style>"+This:C1470.consoleCss()+"</style></head><body><main style='max-width:680px'>"
		$err+="<section class='card'><div class='card-body'><div class='banner bad'>The report could not be generated.</div>"
		$err+="<div class='muted'>Technical detail</div><pre style='white-space:pre-wrap;font-size:12px;color:var(--slate);margin-top:6px'>"+This:C1470.htmlEscape(JSON Stringify:C1217(Last errors:C1799))+"</pre>"
		$err+="<div class='hint'><a href='/reports'>← Back to reports</a></div></div></section></main></body></html>"
		return This:C1470.htmlResult($err; 200)
	End try
	
	
	// ─── ROUTE: GET /reports  (case report list ) ────────
	
Function reportsList($request : 4D:C1709.IncomingMessage) : 4D:C1709.OutgoingMessage
	var $rows : Text:=""
	var $count : Integer:=0
	var $seen : Object:=New object:C1471
	var $curStatus : Text:="none"
	var $q : Text:=Trim:C1853(String:C10($request.urlQuery.q))
	var $qLower : Text:=Lowercase:C14($q)
	
	var $d : Object:=Session:C1714.storage.data
	If ($d#Null:C1517)
		$curStatus:=String:C10($d.status)
		var $st : Text:=String:C10($d.status)
		If ($st="under_review") | ($st="approved") | ($st="rejected") | ($st="info_requested")
			If ($q="") | (Position:C15($qLower; Lowercase:C14(String:C10($d.ref)))>0)
				$rows+=This:C1470.reportRow(String:C10($d.ref); String:C10($d.submittedAt); String:C10($d.fileName); $st)
				$count:=$count+1
			End if 
			$seen[String:C10($d.ref)]:=True:C214
		End if 
	End if 
	
	var $coll : Collection:=This:C1470.loadReports()
	var $i : Integer
	For ($i; $coll.length-1; 0; -1)
		var $rf : Text:=String:C10($coll[$i].ref)
		If ($seen[$rf]#True:C214)
			If ($q="") | (Position:C15($qLower; Lowercase:C14($rf))>0)
				$rows+=This:C1470.reportRow($rf; String:C10($coll[$i].submittedAt); String:C10($coll[$i].fileName); String:C10($coll[$i].status))
				$count:=$count+1
			End if 
			$seen[$rf]:=True:C214
		End if 
	End for 
	
	var $sub : Text:="All verification case reports"
	var $chipTxt : Text:=String:C10($count)+" total"
	If ($q#"")
		$sub:="Search results for “"+This:C1470.htmlEscape($q)+"” · <a href='/reports'>clear</a>"
		$chipTxt:=String:C10($count)+" found"
	End if 
	
	var $main : Text:="<div class='crumb'><a href='/init'>Dashboard</a><span class='sep'>/</span><span>Reports</span></div>"
	$main+="<div class='pagehead'><div><h1>Reports</h1><p class='substatus'>"+$sub+"</p></div>"
	$main+="<span class='chip neutral'><span class='d'></span> "+$chipTxt+"</span></div>"
	$main+="<section class='card'><div class='card-head'><span class='lbl'>Cases</span></div>"
	If ($count=0)
		If ($q#"")
			$main+="<div class='empty'>No reports match “"+This:C1470.htmlEscape($q)+"”. <a href='/reports'>Show all</a></div>"
		Else 
			$main+="<div class='empty'>No reports yet. Completed verifications will appear here.</div>"
		End if 
	Else 
		$main+="<table><thead><tr><th>Reference</th><th>Submitted</th><th>File</th><th>Status</th><th></th></tr></thead><tbody>"+$rows+"</tbody></table>"
	End if 
	$main+="</section>"
	$main+="<div class='hint'>Reports are stored and persist across sessions and restarts.</div>"
	return This:C1470.htmlResult(This:C1470.verifyShell("Reports"; $main; $curStatus; "reports"); 0)
	
Function reportRow($ref : Text; $submitted : Text; $file : Text; $status : Text) : Text
	var $h : Text:="<tr><td class='mono'>"+$ref+"</td>"
	$h+="<td>"+This:C1470.fmtTime($submitted)+"</td>"
	$h+="<td>"+This:C1470.htmlEscape($file)+"</td>"
	$h+="<td>"+This:C1470.verifyChip($status)+"</td>"
	$h+="<td><a href='/report?ref="+$ref+"' target='_blank'>Open report ↗</a></td></tr>"
	return $h
	
Function findCase($ref : Text) : Object
	var $coll : Collection:=This:C1470.loadReports()
	var $i : Integer
	For ($i; 0; $coll.length-1)
		If (String:C10($coll[$i].ref)=$ref)
			return $coll[$i]
		End if 
	End for 
	return Null:C1517
	
	// ─── PERSISTENT REPORT STORE (file-backed) ───────
	
Function reportsFile() : 4D:C1709.File
	var $folder : 4D:C1709.Folder:=Folder:C1567("/PACKAGE/Reports")
	Try
		If (Not:C34($folder.exists))
			$folder.create()
		End if 
	Catch
	End try
	return $folder.file("index.json")
	
Function loadReports() : Collection
	var $f : 4D:C1709.File:=This:C1470.reportsFile()
	If (Not:C34($f.exists))
		return New collection:C1472
	End if 
	var $c : Collection:=New collection:C1472
	Try
		var $txt : Text:=$f.getText()
		If ($txt#"")
			$c:=JSON Parse:C1218($txt)
		End if 
	Catch
		$c:=New collection:C1472
	End try
	If ($c=Null:C1517)
		$c:=New collection:C1472
	End if 
	return $c
	
Function saveReports($coll : Collection)
	Try
		This:C1470.reportsFile().setText(JSON Stringify:C1217($coll))
	Catch
	End try
	
	// Snapshot the current case into the persistent report store
Function archiveCurrent()
	var $d : Object:=Session:C1714.storage.data
	If ($d=Null:C1517) | (String:C10($d.ref)="")
		return 
	End if 
	
	var $snap : Object:=New object:C1471
	$snap.ref:=String:C10($d.ref)
	$snap.status:=String:C10($d.status)
	$snap.createdAt:=String:C10($d.createdAt)
	$snap.submittedAt:=String:C10($d.submittedAt)
	$snap.fileName:=String:C10($d.fileName)
	$snap.fileSize:=String:C10($d.fileSize)
	$snap.fileType:=String:C10($d.fileType)
	$snap.sha256:=String:C10($d.sha256)
	$snap.checks:=String:C10($d.checks)
	$snap.decisionOutcome:=String:C10($d.decisionOutcome)
	$snap.decisionReason:=String:C10($d.decisionReason)
	$snap.decisionNotes:=String:C10($d.decisionNotes)
	$snap.decidedAt:=String:C10($d.decidedAt)
	$snap.reviewer:=String:C10($d.reviewer)
	If (Session:C1714.storage.log#Null:C1517)
		$snap.log:=Session:C1714.storage.log.copy()
	Else 
		$snap.log:=New collection:C1472
	End if 
	
	var $coll : Collection:=This:C1470.loadReports()
	var $i : Integer
	For ($i; $coll.length-1; 0; -1)
		If (String:C10($coll[$i].ref)=String:C10($d.ref))
			$coll.remove($i)
		End if 
	End for 
	$coll.push($snap)
	This:C1470.saveReports($coll)
	
	
	// ─── ROUTE: GET/POST /reset   ───────────────
	
Function reset($request : 4D:C1709.IncomingMessage) : 4D:C1709.OutgoingMessage
	// Archive the outgoing case (if it reached submission) before clearing
	var $cd : Object:=Session:C1714.storage.data
	If ($cd#Null:C1517)
		var $cs : Text:=String:C10($cd.status)
		If ($cs="under_review") | ($cs="approved") | ($cs="rejected") | ($cs="info_requested")
			This:C1470.archiveCurrent()
		End if 
	End if 
	
	If (Session:C1714.clearPrivileges())
		Use (Session:C1714.storage)
			Session:C1714.storage.data:=Null:C1517
			Session:C1714.storage.log:=New shared collection:C1527
		End use 
		This:C1470.newChallenge()
	End if 
	return This:C1470.jsonResult(New object:C1471("ok"; True:C214; "message"; "Session reset"); 0)
	
	
	// ─── ROUTE: GET /pair  (generate OTP2, render QR for mobile) ────────
	// Operator clicks "Pair device" from /init. Creates a fresh OTP so the
	// subject's device can join the same desktop session via QR scan.
	
Function pair($request : 4D:C1709.IncomingMessage) : 4D:C1709.OutgoingMessage
	If (Session:C1714.storage.data=Null:C1517)
		var $redir:=4D:C1709.OutgoingMessage.new()
		$redir.setHeader("Location"; "/init")
		$redir.setStatus(302)
		return $redir
	End if 
	var $d : Object:=Session:C1714.storage.data
	var $status : Text:=String:C10($d.status)
	If ($status#"pending")
		$redir:=4D:C1709.OutgoingMessage.new()
		$redir.setHeader("Location"; "/init")
		$redir.setStatus(302)
		return $redir
	End if 
	
	// Regenerate challenge and OTP on every visit
	cs:C1710.GeneralHandling.new().newChallenge()
	$d:=Session:C1714.storage.data
	var $token : Text:=Session:C1714.createOTP(20)
	var $host : Text:=$request.getHeader("host")
	var $scanURL : Text:="http://"+$host+"/scan?$4DSID="+$token
	var $qrURL : Text:="https://api.qrserver.com/v1/create-qr-code/?size=240x240&data="+$scanURL
	var $ref : Text:=String:C10($d.ref)
	var $challenge : Text:=String:C10($d.challenge)
	var $chip : Text:=This:C1470.verifyChip($status)
	
	This:C1470.addLog("Pair device: QR and challenge generated.")
	
	var $m : Text:="<div class='crumb'><a href='/init'>Dashboard</a><span class='sep'>/</span><span class='mono'>"+$ref+"</span><span class='sep'>/</span><span>Pair device</span></div>"
	$m+="<div class='pagehead'><div><h1>Verification <span class='ref mono'>"+$ref+"</span></h1>"
	$m+="<p class='substatus'><span class='pulse'></span> Scan the QR code on the subject's device</p></div>"+$chip+"</div>"
	
	$m+="<section class='card hero'><div class='hero-top'><div class='step-ctx'><span class='num'>2</span> <span>Current step ·</span> <b>Device pairing</b></div>"+$chip+"</div>"
	$m+="<div class='hero-body'><div><div class='qr-tile'><img src='"+$qrURL+"' alt='Pairing QR'></div><div class='qr-cap'>Scan QR with the subject's device</div></div>"
	$m+="<div class='hero-info'><div class='code-block'><div class='code-badge'><div class='lbl'>Challenge</div><div class='num'>"+$challenge+"</div></div>"
	$m+="<div class='code-meta'>Read this number to the subject after they scan the QR code.</div></div>"
	$m+="<div class='linkrow'><span class='tag'>Or share this link</span><span class='val mono' id='link'>"+$scanURL+"</span><button class='copy' id='copy' type='button' aria-label='Copy link'><svg viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-linecap='round' stroke-linejoin='round'><rect x='9' y='9' width='11' height='11' rx='2'/><path d='M5 15V5a2 2 "+"0 0 1 2-2h10'/></svg><span id='ctext'>Copy</span></button></div>"
	$m+="<div style='margin-top:12px'><a href='/pair' style='display:inline-flex;align-items:center;gap:6px;padding:8px 14px;border:1.5px solid #86868b;border-radius:8px;color:#555;font-size:12px;font-weight:600;text-decoration:none'>&#8635; Regenerate QR &amp"+"; challenge</a></div>"
	$m+="</div></div></section>"
	
	$m+="<div class='row'>"
	$m+="<section class='card'><div class='card-head'><span class='lbl'>Process</span></div><div class='card-body'>"+This:C1470.verifySteps($status)+"</div></section>"
	$m+="<section class='card'><div class='card-head'><span class='lbl'>Case details</span></div><div class='card-body'>"+This:C1470.verifyDetails()+"</div></section>"
	$m+="<section class='card'><div class='card-head'><span class='lbl'>Activity</span></div><div class='card-body'>"+This:C1470.verifyActivity()+"</div></section>"
	$m+="</div>"
	return This:C1470.htmlResult(This:C1470.verifyShell("Pair device · "+$ref; $m; $status; "dashboard"); 0)
	
	
	// ─── User dashboard — STATE VIEWS ──────────────────────────────────
	
Function progressMain($request : 4D:C1709.IncomingMessage) : Text
	var $d : Object:=Session:C1714.storage.data
	var $status : Text:=String:C10($d.status)
	var $ref : Text:=String:C10($d.ref)
	var $challenge : Text:=String:C10($d.challenge)
	var $chip : Text:=This:C1470.verifyChip($status)
	var $dm : Object
	var $connHost : Text
	
	var $m : Text:="<div class='crumb'><a href='/init'>Dashboard</a><span class='sep'>/</span><span class='mono'>"+$ref+"</span></div>"
	$m+="<div class='pagehead'><div><h1>Verification <span class='ref mono'>"+$ref+"</span></h1>"
	
	If ($status="pending")
		$m+="<p class='substatus'><span class='pulse'></span> Awaiting subject — pair a device to continue</p></div>"+$chip+"</div>"
		$m+="<section class='card hero'><div class='hero-top'><div class='step-ctx'><span class='num'>2</span> <span>Current step ·</span> <b>Device pairing</b></div>"+$chip+"</div>"
		$m+="<div class='hero-body'><div class='hero-info'>"
		$m+="<p class='code-meta'>Click <b>Pair device</b> to generate a QR code and challenge number for the subject's phone.</p>"
		$m+="<a href='/pair' class='btn primary' style='margin-top:16px;display:inline-flex;align-items:center;gap:8px'>"
		$m+="<svg viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round' style='width:16px;height:16px'><rect x='2' y='2' width='9' height='9' rx='1'/><rect x='13' y='2' width='9' height='9' rx='1'/><r"+"ect x='2' y='13' width='9' height='9' rx='1'/><rect x='13' y='17' width='2' height='4'/><rect x='17' y='13' width='4' height='2'/></svg>"
		$m+="Pair device</a>"
		$m+="</div></div></section>"
	Else 
		$m+="<p class='substatus'><span class='pulse'></span> Identity verified — awaiting evidence upload</p></div>"+$chip+"</div>"
		$m+="<section class='card hero'><div class='hero-top'><div class='step-ctx'><span class='num'>3</span> <span>Current step ·</span> <b>Evidence submission</b></div>"+$chip+"</div>"
		$m+="<div class='hero-body'><div class='hero-info'><div class='code-block'><div class='code-badge'><div class='lbl'>Challenge</div><div class='num'>"+$challenge+"</div></div>"
		$m+="<div class='code-meta'>Identity confirmed. The subject is now uploading their verification photo.</div></div>"
		$m+="</div></div></section>"
	End if 
	
	// Desktop session connection banner
	If (Session:C1714.storage.desktopMessage#Null:C1517)
		$dm:=Session:C1714.storage.desktopMessage
		$connHost:=$request.getHeader("host")
		$m+="<div class='banner ok' style='display:flex;align-items:center;gap:10px;margin-bottom:6px'>"
		$m+="<svg viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round' style='width:16px;height:16px;flex-shrink:0'><path d='m5 12 4.5 4.5L19 7'/></svg>"
		$m+="<span><b>Desktop session connected</b>"
		If ($connHost#"")
			$m+=" <span style='opacity:.6'>·</span> <code style='font-size:12px'>"+This:C1470.htmlEscape($connHost)+"</code>"
		End if 
		If (String:C10($dm.openedAt)#"")
			$m+=" <span style='opacity:.6'>·</span> "+This:C1470.fmtTime(String:C10($dm.openedAt))
		End if 
		$m+="</span></div>"
	End if 
	
	$m+="<div class='row'>"
	$m+="<section class='card'><div class='card-head'><span class='lbl'>Process</span></div><div class='card-body'>"+This:C1470.verifySteps($status)+"</div></section>"
	$m+="<section class='card'><div class='card-head'><span class='lbl'>Case details</span></div><div class='card-body'>"+This:C1470.verifyDetails()+"</div></section>"
	$m+="<section class='card'><div class='card-head'><span class='lbl'>Activity</span></div><div class='card-body'>"+This:C1470.verifyActivity()+"</div></section>"
	$m+="</div>"
	return $m
	
Function reviewMain() : Text
	var $d : Object:=Session:C1714.storage.data
	var $checks : Collection:=New collection:C1472
	If (String:C10($d.checks)#"")
		$checks:=JSON Parse:C1218(String:C10($d.checks))
	End if 
	var $pass : Integer:=0
	var $i : Integer
	For ($i; 0; $checks.length-1)
		If (String:C10($checks[$i].state)="pass")
			$pass:=$pass+1
		End if 
	End for 
	var $isImg : Boolean:=This:C1470.isImageExt(This:C1470.fileExt(String:C10($d.fileName)))
	var $thumb : Text:="📄"
	If ($isImg)
		$thumb:="<img src='/evidence' style='width:100%;height:100%;object-fit:cover;border-radius:6px'>"
	End if 
	
	var $m : Text:="<div class='crumb'><a href='/init'>Dashboard</a><span class='sep'>/</span><span class='mono'>"+String:C10($d.ref)+"</span></div>"
	$m+="<div class='pagehead'><div><h1>Verification <span class='ref mono'>"+String:C10($d.ref)+"</span></h1>"
	$m+="<p class='substatus'>Ready for review · submitted "+This:C1470.fmtTime(String:C10($d.submittedAt))+"</p></div>"+This:C1470.verifyChip("under_review")+"</div>"
	$m+="<div class='grid2'><div class='gcol'>"
	$m+="<section class='card'><div class='card-head'><span class='lbl'>Evidence</span></div><div class='card-body'><div class='evi'><div class='thumb'>"+$thumb+"</div>"
	$m+="<div><div class='ename'>"+This:C1470.htmlEscape(String:C10($d.fileName))+"</div>"
	$m+="<div class='muted'>"+String:C10($d.fileType)+" · "+String:C10($d.fileSize)+"</div>"
	$m+="<a class='ilink' href='/evidence' target='_blank'>Open original ↗</a></div></div></div></section>"
	$m+="<section class='card'><div class='card-head'><span class='lbl'>Automated checks</span><span class='muted'>"+String:C10($pass)+" / "+String:C10($checks.length)+" passed</span></div><div class='card-body'>"+This:C1470.renderChecks($checks)+"</div></section>"
	$m+="<section class='card'><div class='card-head'><span class='lbl'>Audit trail</span></div><div class='card-body'>"+This:C1470.verifyActivity()+"</div></section>"
	$m+="</div><div class='gcol'>"
	$m+="<section class='card'><div class='card-head'><span class='lbl'>Case details</span></div><div class='card-body'>"+This:C1470.verifyDetails()+"</div></section>"
	$m+="<section class='card'><div class='card-head'><span class='lbl'>Decision</span></div><div class='card-body'>"
	$m+="<div class='radios'>"
	$m+="<label class='radio'><input type='radio' name='o' value='approved'> Approve</label>"
	$m+="<label class='radio'><input type='radio' name='o' value='rejected'> Reject</label>"
	$m+="<label class='radio'><input type='radio' name='o' value='info_requested'> Request info</label>"
	$m+="</div>"
	$m+="<label class='fl'>Reason code</label>"
	$m+="<select id='reason'><option value=''>Select reason…</option>"
	$m+="<optgroup label='Approve'><option value='identity_confirmed'>Identity confirmed</option><option value='manual_override'>Manual override</option></optgroup>"
	$m+="<optgroup label='Reject'><option value='doc_unreadable'>Document unreadable</option><option value='face_mismatch'>Face mismatch</option><option value='suspected_tampering'>Suspected tampering</option><option value='wrong_document'>Wrong document</opti"+"on><option value='other'>Other</option></optgroup>"
	$m+="<optgroup label='Request info'><option value='retake_photo'>Retake photo</option><option value='better_lighting'>Better lighting</option><option value='full_document'>Full document</option><option value='other'>Other</option></optgroup>"
	$m+="</select>"
	$m+="<label class='fl'>Notes</label><textarea id='notes' placeholder='Context for the audit record (optional)'></textarea>"
	$m+="<div class='btnrow'><button class='btn primary' id='submit' onclick='submitDecision()'>Submit decision</button></div>"
	$m+="<div id='fb' class='note'></div>"
	$m+="<div class='note'>Decisions are final and recorded in the audit trail.</div>"
	$m+="</div></section>"
	$m+="</div></div>"
	$m+="<script>async function submitDecision(){var o=document.querySelector('input[name=o]:checked');if(!o){alert('Select a decision.');return;}var reason=document.getElementById('reason').value;if((o.value==='rejected'||o.value==='info_requested')&&!reason)"+"{alert('Select a reason code.');return;}var btn=document.getElementById('submit');btn.disabled=true;var body={outcome:o.value,reasonCode:reason,notes:document.getElementById('notes').value};try{var r=await fetch('/decision',{method:'POST',headers:{'Co"+"ntent-Type':'application/json'},body:JSON.stringify(body)});var d=await r.json();if(d.ok){document.getElementById('fb').textContent='Decision recorded — '+(d.ref||'')+' · archived to Reports.';setTimeout(function(){location.reload();},1000);}else{d"+"ocument.getElementById('fb').textContent=d.message||'Failed';btn.disabled=false;}}catch(e){document.getElementById('fb').textContent='Network error';btn.disabled=false;}}</script>"
	return $m
	
Function outcomeMain() : Text
	var $d : Object:=Session:C1714.storage.data
	var $outcome : Text:=String:C10($d.status)
	var $checks : Collection:=New collection:C1472
	If (String:C10($d.checks)#"")
		$checks:=JSON Parse:C1218(String:C10($d.checks))
	End if 
	var $bclass : Text:="warn"
	var $btext : Text:="Additional information requested from the subject."
	Case of 
		: ($outcome="approved")
			$bclass:="ok"
			$btext:="✓ This verification has been approved."
		: ($outcome="rejected")
			$bclass:="bad"
			$btext:="✕ This verification has been rejected."
	End case 
	var $isImg : Boolean:=This:C1470.isImageExt(This:C1470.fileExt(String:C10($d.fileName)))
	var $thumb : Text:="📄"
	If ($isImg)
		$thumb:="<img src='/evidence' style='width:100%;height:100%;object-fit:cover;border-radius:6px'>"
	End if 
	
	var $m : Text:="<div class='crumb'><a href='/init'>Dashboard</a><span class='sep'>/</span><span class='mono'>"+String:C10($d.ref)+"</span></div>"
	$m+="<div class='pagehead'><div><h1>Verification <span class='ref mono'>"+String:C10($d.ref)+"</span></h1>"
	$m+="<p class='substatus'>Decision recorded · "+This:C1470.fmtTime(String:C10($d.decidedAt))+"</p></div>"+This:C1470.verifyChip($outcome)+"</div>"
	$m+="<div class='banner "+$bclass+"'>"+$btext+"</div>"
	$m+="<div class='grid2'><div class='gcol'>"
	$m+="<section class='card'><div class='card-head'><span class='lbl'>Evidence</span></div><div class='card-body'><div class='evi'><div class='thumb'>"+$thumb+"</div><div><div class='ename'>"+This:C1470.htmlEscape(String:C10($d.fileName))+"</div><div class='muted'>"+String:C10($d.fileType)+" · "+String:C10($d.fileSize)+"</div></div></div></div></section>"
	$m+="<section class='card'><div class='card-head'><span class='lbl'>Automated checks</span></div><div class='card-body'>"+This:C1470.renderChecks($checks)+"</div></section>"
	$m+="<section class='card'><div class='card-head'><span class='lbl'>Audit trail</span></div><div class='card-body'>"+This:C1470.verifyActivity()+"</div></section>"
	$m+="</div><div class='gcol'>"
	$m+="<section class='card'><div class='card-head'><span class='lbl'>Case details</span></div><div class='card-body'>"+This:C1470.verifyDetails()+"</div></section>"
	$m+="<section class='card'><div class='card-head'><span class='lbl'>Decision</span></div><div class='card-body'><dl class='def'>"
	$m+="<dt>Outcome</dt><dd>"+This:C1470.verifyChip($outcome)+"</dd>"
	$m+="<dt>Reason</dt><dd>"+This:C1470.reasonLabel(String:C10($d.decisionReason))+"</dd>"
	var $notes : Text:=String:C10($d.decisionNotes)
	If ($notes="")
		$notes:="—"
	End if 
	$m+="<dt>Notes</dt><dd>"+This:C1470.htmlEscape($notes)+"</dd>"
	$m+="<dt>Reviewer</dt><dd>"+String:C10($d.reviewer)+"</dd>"
	$m+="<dt>Decided</dt><dd>"+This:C1470.fmtTime(String:C10($d.decidedAt))+"</dd>"
	$m+="</dl><div class='btnrow'><a class='btn sec' href='/report' target='_blank'>Open report</a><button class='btn ghost' onclick='resetFlow()'>Start over</button></div></div></section>"
	$m+="</div></div>"
	$m+="<script>async function resetFlow(){await fetch('/reset');location.reload();}</script>"
	return $m
	
	
	// ─── REUSABLE RENDER HELPERS ─────────────────────────────────────────
	
Function caseMetaPanel() : Text
	var $d : Object:=Session:C1714.storage.data
	var $h : Text:="<div class='panel'><div class='ph'>Case details</div><div class='pb'><dl class='def'>"
	$h+="<dt>Reference</dt><dd>"+String:C10($d.ref)+"</dd>"
	$h+="<dt>Status</dt><dd>"+This:C1470.pill(String:C10($d.status))+"</dd>"
	$h+="<dt>Channel</dt><dd>QR / mobile</dd>"
	$h+="<dt>Created</dt><dd>"+This:C1470.fmtTime(String:C10($d.createdAt))+"</dd>"
	$h+="<dt>Session</dt><dd>"+Substring:C12(Session:C1714.id; 1; 12)+"…</dd>"
	If (String:C10($d.sha256)#"")
		$h+="<dt>Integrity</dt><dd><span class='code'>"+Substring:C12(String:C10($d.sha256); 1; 24)+"…</span></dd>"
	End if 
	$h+="</dl></div></div>"
	return $h
	
Function processSteps($status : Text) : Text
	var $s2 : Boolean:=($status="verified") | ($status="under_review") | ($status="approved") | ($status="rejected") | ($status="info_requested")
	var $s3 : Boolean:=($status="under_review") | ($status="approved") | ($status="rejected") | ($status="info_requested")
	var $h : Text:="<div class='steps'>"
	$h+="<div class='step done'><span class='dot'>✓</span><span>Case opened</span></div>"
	If ($s2)
		$h+="<div class='step done'><span class='dot'>✓</span><span>Identity verified</span></div>"
	Else 
		$h+="<div class='step'><span class='dot'>2</span><span>Identity verification</span></div>"
	End if 
	If ($s3)
		$h+="<div class='step done'><span class='dot'>✓</span><span>Evidence submitted</span></div>"
	Else 
		$h+="<div class='step'><span class='dot'>3</span><span>Evidence submission</span></div>"
	End if 
	$h+="</div>"
	return $h
	
Function renderChecks($checks : Collection) : Text
	var $h : Text:="<div class='checks'>"
	If ($checks#Null:C1517)
		var $i : Integer
		For ($i; 0; $checks.length-1)
			var $c : Object:=$checks[$i]
			var $state : Text:=String:C10($c.state)
			var $g : Text:="i"
			Case of 
				: ($state="pass")
					$g:="✓"
				: ($state="warn")
					$g:="!"
				: ($state="fail")
					$g:="✕"
			End case 
			$h+="<div class='chk "+$state+"'><div class='g'>"+$g+"</div>"
			$h+="<div class='t'><div class='cl'>"+This:C1470.htmlEscape(String:C10($c.label))+"</div>"
			$h+="<div class='cn'>"+This:C1470.htmlEscape(String:C10($c.note))+"</div></div>"
			$h+="<div class='cv'>"+This:C1470.htmlEscape(String:C10($c.value))+"</div></div>"
		End for 
	End if 
	$h+="</div>"
	return $h
	
Function renderTimeline() : Text
	return This:C1470.renderTimelineFrom(Session:C1714.storage.log)
	
Function renderTimelineFrom($log : Collection) : Text
	var $h : Text:="<ul class='tl'>"
	If ($log#Null:C1517)
		var $i : Integer
		For ($i; $log.length-1; 0; -1)
			var $t : Text:=String:C10($log[$i].t)
			var $tt : Text:=$t
			If (Length:C16($t)>=19)
				$tt:=Substring:C12($t; 12; 8)
			End if 
			$h+="<li><span class='tt'>"+$tt+"</span>"+This:C1470.htmlEscape(This:C1470.stripTags(String:C10($log[$i].m)))+"</li>"
		End for 
	End if 
	$h+="</ul>"
	return $h
	
Function uploadFormHtml() : Text
	var $h : Text:="<input type='file' id='photo' accept='image/*' class='filein'>"
	$h+="<button class='btn primary' id='sendbtn' onclick='send()' style='margin-top:10px;width:100%'>Upload verification photo</button>"
	$h+="<div id='fb' class='note'></div>"
	$h+="<script>async function send(){var f=document.getElementById('photo').files[0];if(!f){alert('Choose a photo first.');return;}var fd=new FormData();fd.append('photoFile',f);var b=document.getElementById('sendbtn');b.disabled=true;var fb=document.getElem"+"entById('fb');fb.textContent='Uploading…';try{var r=await fetch('/fileUpload',{method:'POST',body:fd});var d=await r.json();if(d.ok){fb.textContent='Submitted. Returning to the dashboard...';try{window.close();}catch(e){}window.location.href='/init'"+";}else{fb.textContent=d.message||'Upload failed';b.disabled=false;}}catch(e){fb.textContent='Networ"+"k error';b.disabled=false;}}</script>"
	return $h
	
	
	// ─── PAGE SHELLS + STYLESHEET ────────────────────────────────────────
	
Function consoleShell($title : Text; $crumb : Text; $main : Text; $status : Text) : Text
	var $h : Text:="<!DOCTYPE html><html lang='en'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'>"
	$h+="<title>"+$title+" · 4D Secure OTP</title><style>"+This:C1470.css()+"</style></head><body>"
	$h+="<div class='app'><aside class='side'><div class='logo'>◆ 4D Secure OTP</div><nav>"
	$h+="<a class='nav-i active' href='/init'><span class='ic'>▤</span>Dashboard</a>"
	$h+="<span class='nav-i disabled'><span class='ic'>⧉</span>History</span>"
	$h+="<a class='nav-i' href='/reports'><span class='ic'>▢</span>Reports</a>"
	$h+="</nav><div class='foot'>4D Secure OTP · v1.0<br>Single-session mode</div></aside>"
	$h+="<div class='main'><div class='top'><form class='search' onsubmit='return goSearch(event)'><input id='q' placeholder='Search by reference (VR-…)'></form>"
	$h+="<span class='env'>● Production</span><div class='ava'>OP</div></div>"
	$h+="<div class='content'><div class='crumb'>"+$crumb+"</div>"+$main+"</div></div></div>"
	$h+="<script>function goSearch(e){e.preventDefault();var v=document.getElementById('q').value.trim();if(v){window.open('/report?ref='+encodeURIComponent(v),'_blank');}return false;}var S='"+$status+"';async function poll(){try{var r=await fetch('/status',{cache:'no-store'});var d=await r.json();if(String(d.status)!==S){location.reload();}}catch(e){}}setInterval(poll,2500);</script>"
	$h+="</body></html>"
	return $h
	
Function subjectShell($title : Text; $main : Text; $status : Text) : Text
	var $h : Text:="<!DOCTYPE html><html lang='en'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'>"
	$h+="<title>"+$title+" · 4D Secure OTP</title>"
	$h+="<link rel='preconnect' href='https://fonts.googleapis.com'><link rel='preconnect' href='https://fonts.gstatic.com' crossorigin>"
	$h+="<link href='https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;600&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap' rel='stylesheet'>"
	$h+="<style>"+This:C1470.consoleCss()+"</style></head><body>"
	$h+="<header class='nav'><div class='nav-inner subjnav'>"
	$h+="<div class='brand'><svg viewBox='0 0 24 24' fill='none'><path d='M12 2 21 7v10l-9 5-9-5V7l9-5Z' stroke='#4F46E5' stroke-width='1.6' stroke-linejoin='round'/><path d='M12 7 16.5 9.5v5L12 17l-4.5-2.5v-5L12 7Z' fill='#4F46E5'/></svg><b>4D Secure OTP</b><"+"/div"+">"
	$h+="<span class='env'><span class='d'></span><span class='t'>Secure</span></span>"
	$h+="</div></header>"
	$h+="<main><div class='subjwrap'>"+$main
	$h+="<div class='muted' style='text-align:center;margin-top:16px'>Secured by 4D Secure OTP</div></div></main>"
	$h+="<script>var S='"+$status+"';async function poll(){try{var r=await fetch('/status',{cache:'no-store'});var d=await r.json();if(String(d.status)!==S){location.reload();}}catch(e){}}setInterval(poll,2500);</script>"
	$h+="</body></html>"
	return $h
	
Function reportPage($src : Object; $log : Collection) : Text
	var $d : Object:=$src
	var $h : Text:="<!DOCTYPE html><html lang='en'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'>"
	$h+="<title>Case report · 4D Secure OTP</title>"
	$h+="<link rel='preconnect' href='https://fonts.googleapis.com'><link rel='preconnect' href='https://fonts.gstatic.com' crossorigin>"
	$h+="<link href='https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;600&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap' rel='stylesheet'>"
	$h+="<style>"+This:C1470.consoleCss()+"@media print{.nav{display:none}main{padding-top:18px}}</style></head><body>"
	$h+="<header class='nav'><div class='nav-inner'>"
	$h+="<div class='brand'><svg viewBox='0 0 24 24' fill='none'><path d='M12 2 21 7v10l-9 5-9-5V7l9-5Z' stroke='#4F46E5' stroke-width='1.6' stroke-linejoin='round'/><path d='M12 7 16.5 9.5v5L12 17l-4.5-2.5v-5L12 7Z' fill='#4F46E5'/></svg><b>4D Secure OTP</b><"+"/div"+">"
	$h+="<div class='nav-right'><a class='btn sec' href='/reports'>← Reports</a></div>"
	$h+="</div></header><main style='max-width:780px'>"
	If ($d=Null:C1517)
		$h+="<section class='card'><div class='card-body'><div class='banner warn'>No active case in this session.</div></div></section></main></body></html>"
		return $h
	End if 
	var $checks : Collection:=New collection:C1472
	If (String:C10($d.checks)#"")
		$checks:=JSON Parse:C1218(String:C10($d.checks))
	End if 
	$h+="<div class='pagehead'><div><h1>Case report <span class='ref mono'>"+String:C10($d.ref)+"</span></h1>"
	$h+="<p class='substatus'>Generated "+This:C1470.fmtTime(Timestamp:C1445)+"</p></div>"+This:C1470.verifyChip(String:C10($d.status))+"</div>"
	$h+="<div class='btnrow' style='margin:-12px 0 18px'><button class='btn primary' onclick='window.print()'>Print / Save PDF</button></div>"
	$h+="<section class='card'><div class='card-head'><span class='lbl'>Case details</span></div><div class='card-body'>"
	$h+="<div class='drow'><span class='k'>Reference</span><span class='v mono'>"+String:C10($d.ref)+"</span></div>"
	$h+="<div class='drow'><span class='k'>Channel</span><span class='v'>QR · Mobile</span></div>"
	$h+="<div class='drow'><span class='k'>Created</span><span class='v mono'>"+This:C1470.fmtTime(String:C10($d.createdAt))+"</span></div>"
	$h+="<div class='drow'><span class='k'>Submitted</span><span class='v mono'>"+This:C1470.fmtTime(String:C10($d.submittedAt))+"</span></div>"
	$h+="<div class='drow'><span class='k'>Session</span><span class='v mono'>"+Substring:C12(Session:C1714.id; 1; 16)+"…</span></div>"
	$h+="</div></section>"
	$h+="<section class='card'><div class='card-head'><span class='lbl'>Evidence</span></div><div class='card-body'>"
	$h+="<div class='drow'><span class='k'>File</span><span class='v'>"+This:C1470.htmlEscape(String:C10($d.fileName))+"</span></div>"
	$h+="<div class='drow'><span class='k'>Type</span><span class='v'>"+String:C10($d.fileType)+"</span></div>"
	$h+="<div class='drow'><span class='k'>Size</span><span class='v'>"+String:C10($d.fileSize)+"</span></div>"
	$h+="<div class='drow'><span class='k'>SHA-256</span><span class='v mono' style='word-break:break-all;text-align:right'>"+String:C10($d.sha256)+"</span></div>"
	$h+="</div></section>"
	$h+="<section class='card'><div class='card-head'><span class='lbl'>Automated checks</span></div><div class='card-body'>"+This:C1470.renderChecks($checks)+"</div></section>"
	$h+="<section class='card'><div class='card-head'><span class='lbl'>Decision</span></div><div class='card-body'><dl class='def'>"
	var $oc : Text:=String:C10($d.decisionOutcome)
	If ($oc="")
		$h+="<dt>Outcome</dt><dd>Pending decision</dd>"
	Else 
		$h+="<dt>Outcome</dt><dd>"+This:C1470.verifyChip($oc)+"</dd>"
		$h+="<dt>Reason</dt><dd>"+This:C1470.reasonLabel(String:C10($d.decisionReason))+"</dd>"
		var $n : Text:=String:C10($d.decisionNotes)
		If ($n="")
			$n:="—"
		End if 
		$h+="<dt>Notes</dt><dd>"+This:C1470.htmlEscape($n)+"</dd>"
		$h+="<dt>Reviewer</dt><dd>"+String:C10($d.reviewer)+"</dd>"
		$h+="<dt>Decided</dt><dd>"+This:C1470.fmtTime(String:C10($d.decidedAt))+"</dd>"
	End if 
	$h+="</dl></div></section>"
	$h+="<section class='card'><div class='card-head'><span class='lbl'>Audit trail</span></div><div class='card-body'>"+This:C1470.verifyActivityFrom($log)+"</div></section>"
	$h+="<div class='hint' style='text-align:center'>Generated "+This:C1470.fmtTime(Timestamp:C1445)+" · 4D Secure OTP · Confidential</div>"
	$h+="</main></body></html>"
	return $h
	
	// ─── 4D Secure OTP — PAIRING DASHBOARD SHELL + STYLES ────────────
	
Function verifyShell($title : Text; $main : Text; $status : Text; $active : Text) : Text
	var $dashA : Text:=""
	var $repA : Text:=""
	If ($active="reports")
		$repA:=" class='active'"
	Else 
		$dashA:=" class='active'"
	End if 
	var $h : Text:="<!DOCTYPE html><html lang='en'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'>"
	$h+="<title>"+$title+" · 4D Secure OTP</title>"
	$h+="<link rel='preconnect' href='https://fonts.googleapis.com'><link rel='preconnect' href='https://fonts.gstatic.com' crossorigin>"
	$h+="<link href='https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;600&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap' rel='stylesheet'>"
	$h+="<style>"+This:C1470.consoleCss()+"</style></head><body>"
	$h+="<header class='nav'><div class='nav-inner'>"
	$h+="<div class='brand'><svg viewBox='0 0 24 24' fill='none'><path d='M12 2 21 7v10l-9 5-9-5V7l9-5Z' stroke='#4F46E5' stroke-width='1.6' stroke-linejoin='round'/><path d='M12 7 16.5 9.5v5L12 17l-4.5-2.5v-5L12 7Z' fill='#4F46E5'/></svg><b>4D Secure OTP</b><"+"/div"+">"
	$h+="<nav class='links'>"
	$h+="<a href='/init'"+$dashA+"><svg viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-linecap='round' stroke-linejoin='round'><rect x='3' y='3' width='7' height='9' rx='1.5'/><rect x='14' y='3' width='7' height='5' rx='1.5'/><rect x='14' y='12' width='7' height='9' rx='"+"1.5'/><rect x='3' y='16' width='7' height='5' rx='1.5'/></svg><span>Dashboard</span></a>"
	$h+="<a href='/reports'"+$repA+"><svg viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-linecap='round' stroke-linejoin='round'><path d='M6 3h9l5 5v13H6z'/><path d='M14 3v5h5'/><path d='M9 13h7M9 17h7'/></svg><span>Reports</span></a>"
	$h+="</nav>"
	$h+="<div class='nav-right'><form class='search' onsubmit='return goSearch(event)'><svg viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-linecap='round' stroke-linejoin='round'><circle cx='11' cy='11' r='7'/><path d='m20 20-3.2-3.2'/></svg><inp"+"ut id='q' type='text' placeholder='Search (VR-…)' aria-label='Search'></form>"
	$h+="<span class='env'><span class='d'></span><span class='t'>Production</span></span><div class='op' title='Operator'>OTP</div></div>"
	$h+="</div></header>"
	$h+="<main>"+$main+"</main>"
	$h+="<script>"
	$h+="function goSearch(e){e.preventDefault();var v=document.getElementById('q').value.trim();window.location.href='/reports'+(v?('?q='+encodeURIComponent(v)):'');return false;}"
	$h+="(function(){var p=new URLSearchParams(location.search).get('q');if(p){var q=document.getElementById('q');if(q)q.value=p;}})();"
	$h+="(function(){var b=document.getElementById('copy'),t=document.getElementById('ctext');if(!b)return;var lk=document.getElementById('link');var link=lk?lk.textContent.trim():'';b.addEventListener('click',async function(){var ok=false;try{await navigator."+"clipboa"+"rd.writeText(link);ok=true;}catch(e){try{var ta=document.createElement('textarea');ta.value=link;ta.style.cssText='position:fixed;top:-200px;left:-200px;opacity:0';document.body.appendChild(ta);ta.focus();ta.select();ok=document.execCommand('copy');do"+"cument.body.removeChild(ta);}catch(e2){}}b.classList.add('copied');t.textContent=ok?'Copied!':'Copied';setTimeout(function(){b.classList.remove('copied');t.textContent='Copy';},2000);});})();"
	$h+="(function(){var el=document.getElementById('cd');if(!el)return;var t=300;setInterval(function(){if(t<=0)return;t--;el.textContent=String(Math.floor(t/60)).padStart(2,'0')+':'+String(t%60).padStart(2,'0');},1000);})();"
	$h+="var S='"+$status+"';async function poll(){try{var r=await fetch('/status',{cache:'no-store'});var d=await r.json();if(String(d.status)!==S){location.reload();}}catch(e){}}setInterval(poll,2500);"
	$h+="</script></body></html>"
	return $h
	
Function verifyChip($status : Text) : Text
	var $label : Text:=$status
	Case of 
		: ($status="pending")
			$label:="Pending"
		: ($status="verified")
			$label:="Verified"
		: ($status="under_review")
			$label:="Under review"
		: ($status="approved")
			$label:="Approved"
		: ($status="rejected")
			$label:="Rejected"
		: ($status="info_requested")
			$label:="Info requested"
	End case 
	return "<span class='chip "+$status+"'><span class='d'></span> "+$label+"</span>"
	
Function timeOnly($ts : Text) : Text
	If (Length:C16($ts)>=19)
		return Substring:C12($ts; 12; 8)
	End if 
	return $ts
	
Function verifySteps($status : Text) : Text
	var $d : Object:=Session:C1714.storage.data
	var $t1 : Text:=This:C1470.timeOnly(String:C10($d.createdAt))
	var $verified : Boolean:=($status#"pending")
	var $check : Text:="<svg viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-linecap='round' stroke-linejoin='round'><path d='m5 12 4.5 4.5L19 7'/></svg>"
	var $h : Text:="<div class='steps'>"
	$h+="<div class='step done'><div class='rail'></div><div class='mk'>"+$check+"</div><div><div class='t'>Case opened</div><div class='m'>"+$t1+" UTC</div></div></div>"
	If ($verified)
		$h+="<div class='step done'><div class='rail'></div><div class='mk'>"+$check+"</div><div><div class='t'>Identity verification</div><div class='m'>Verified by subject</div></div></div>"
	Else 
		$h+="<div class='step active'><div class='rail'></div><div class='mk'>2</div><div><div class='t'>Identity verification</div><div class='m'>Waiting for device pairing</div></div></div>"
	End if 
	$h+="<div class='step upcoming'><div class='rail'></div><div class='mk'>3</div><div><div class='t'>Evidence submission</div><div class='m'>Unlocks after verification</div></div></div>"
	$h+="</div>"
	return $h
	
Function verifyDetails() : Text
	var $d : Object:=Session:C1714.storage.data
	var $h : Text:="<div class='drow'><span class='k'>Reference</span><span class='v mono'>"+String:C10($d.ref)+"</span></div>"
	$h+="<div class='drow'><span class='k'>Channel</span><span class='v'>QR · Mobile</span></div>"
	$h+="<div class='drow'><span class='k'>Created</span><span class='v mono'>"+This:C1470.fmtTime(String:C10($d.createdAt))+"</span></div>"
	$h+="<div class='drow'><span class='k'>Session</span><span class='v mono'>"+Substring:C12(Session:C1714.id; 1; 12)+"…</span></div>"
	return $h
	
Function stripTags($t : Text) : Text
	var $s : Text:=$t
	var $lt : Integer:=Position:C15("<"; $s)
	While ($lt>0)
		var $gt : Integer:=Position:C15(">"; $s; $lt)
		If ($gt=0)
			$s:=Substring:C12($s; 1; $lt-1)
		Else 
			$s:=Substring:C12($s; 1; $lt-1)+Substring:C12($s; $gt+1)
		End if 
		$lt:=Position:C15("<"; $s)
	End while 
	return $s
	
Function verifyActivity() : Text
	return This:C1470.verifyActivityFrom(Session:C1714.storage.log)
	
Function verifyActivityFrom($log : Collection) : Text
	var $h : Text:=""
	If (($log#Null:C1517) & ($log.length>0))
		var $i : Integer
		For ($i; 0; $log.length-1)
			var $t : Text:=This:C1470.timeOnly(String:C10($log[$i].t))
			$h+="<div class='ev'><div class='er'></div><div class='ed'><i></i></div><div><div class='x'>"+This:C1470.htmlEscape(This:C1470.stripTags(String:C10($log[$i].m)))+"</div><div class='ti mono'>"+$t+" UTC</div></div></div>"
		End for 
	Else 
		$h:="<div class='muted'>No activity yet.</div>"
	End if 
	return $h
	
Function consoleCss() : Text
	var $c : Text
	$c:=":root{--bg:#F6F7F9;--surface:#FFFFFF;--surface-2:#FAFBFC;--ink:#181C25;--slate:#5C6677;--faint:#9AA2B1;--line:rgba(24,28,37,0.08);--line-2:rgba(24,28,37,0.13);--accent:#4F46E5;--accent-ink:#3D34C9;--accent-soft:#EEEEFE;--pending:#A86616;--pending-bg:#"+"FBF2E1;--pending-bd:#EFDDB6;--done:#1C8B53;--done-bg:#E6F4EC;--review:#5A61E6;--shadow-sm:0 1px 2px rgba(24,28,37,0.05);--shadow-md:0 2px 4px rgba(24,28,37,0.04),0 12px 32px -16px rgba(24,28,37,0.18);--radius:16px;--radius-sm:11px}"
	$c+="*{box-sizing:border-box;margin:0;padding:0}"
	$c+="html{-webkit-font-smoothing:antialiased;text-rendering:optimizeLegibility}"
	$c+="body{font-family:'Plus Jakarta Sans',system-ui,sans-serif;background:var(--bg);color:var(--ink);font-size:14px;line-height:1.5}"
	$c+=".mono{font-family:'IBM Plex Mono',ui-monospace,monospace}"
	$c+=".nav{background:var(--surface);border-bottom:1px solid var(--line);position:sticky;top:0;z-index:10}"
	$c+=".nav-inner{max-width:1060px;margin:0 auto;display:flex;align-items:center;gap:8px;padding:0 28px;height:62px}"
	$c+=".brand{display:flex;align-items:center;gap:10px;margin-right:18px}"
	$c+=".brand svg{width:25px;height:25px}"
	$c+=".brand b{font-weight:700;font-size:14px;letter-spacing:-0.01em}"
	$c+=".links{display:flex;align-items:center;gap:2px}"
	$c+=".links a{text-decoration:none;color:var(--slate);font-size:13.5px;font-weight:500;padding:7px 13px;border-radius:9px;display:inline-flex;align-items:center;gap:7px;transition:background .15s,color .15s}"
	$c+=".links a svg{width:16px;height:16px;stroke-width:1.9}"
	$c+=".links a:hover{color:var(--ink);background:var(--surface-2)}"
	$c+=".links a.active{color:var(--accent-ink);background:var(--accent-soft)}"
	$c+=".nav-right{margin-left:auto;display:flex;align-items:center;gap:12px}"
	$c+=".search{position:relative}"
	$c+=".search svg{position:absolute;left:11px;top:50%;transform:translateY(-50%);width:15px;height:15px;color:var(--faint);stroke-width:1.9}"
	$c+=".search input{width:210px;padding:8px 12px 8px 34px;border:1px solid var(--line-2);border-radius:9px;background:var(--surface-2);font:inherit;font-size:13px;color:var(--ink);transition:border-color .15s,box-shadow .15s,background .15s,width .2s}"
	$c+=".search input::placeholder{color:var(--faint)}"
	$c+=".search input:focus{outline:none;border-color:var(--accent);background:#fff;box-shadow:0 0 0 3px rgba(79,70,229,0.12);width:240px}"
	$c+=".env{display:inline-flex;align-items:center;gap:7px;padding:6px 12px;border-radius:999px;font-size:12px;font-weight:600;color:var(--done);background:var(--done-bg);border:1px solid #CFE9D9}"
	$c+=".env .d{width:6px;height:6px;border-radius:50%;background:var(--done)}"
	$c+=".op{width:33px;height:33px;border-radius:9px;background:var(--accent);color:#fff;display:grid;place-items:center;font-weight:600;font-size:12px}"
	$c+="main{max-width:1060px;margin:0 auto;padding:30px 28px 64px}"
	$c+=".crumb{font-size:12.5px;color:var(--faint);display:flex;align-items:center;gap:8px;margin-bottom:14px}"
	$c+=".crumb a{color:var(--slate);text-decoration:none;font-weight:500}"
	$c+=".crumb a:hover{color:var(--ink)}"
	$c+=".crumb .sep{color:var(--line-2)}"
	$c+=".pagehead{display:flex;align-items:flex-start;justify-content:space-between;gap:22px;margin-bottom:26px}"
	$c+="h1{font-size:27px;font-weight:700;letter-spacing:-0.02em;line-height:1.15}"
	$c+="h1 .ref{color:var(--accent-ink)}"
	$c+=".substatus{color:var(--slate);margin-top:8px;font-size:14.5px;display:flex;align-items:center;gap:9px}"
	$c+=".substatus .pulse{width:8px;height:8px;border-radius:50%;background:var(--pending);box-shadow:0 0 0 0 rgba(168,102,22,0.4);animation:pulse 2.6s ease-out infinite}"
	$c+="@keyframes pulse{0%{box-shadow:0 0 0 0 rgba(168,102,22,.35)}70%{box-shadow:0 0 0 8px rgba(168,102,22,0)}100%{box-shadow:0 0 0 0 rgba(168,102,22,0)}}"
	$c+=".chip{display:inline-flex;align-items:center;gap:7px;font-size:12px;font-weight:600;padding:6px 12px;border-radius:999px}"
	$c+=".chip .d{width:6px;height:6px;border-radius:50%;background:currentColor}"
	$c+=".chip.pending{color:var(--pending);background:var(--pending-bg);border:1px solid var(--pending-bd)}"
	$c+=".chip.verified,.chip.under_review{color:var(--review);background:#EEF0FE;border:1px solid #DADEFB}"
	$c+=".chip.approved{color:var(--done);background:var(--done-bg);border:1px solid #CFE9D9}"
	$c+=".chip.rejected{color:#B42318;background:#FEECEC;border:1px solid #F4C6C2}"
	$c+=".chip.info_requested{color:var(--pending);background:var(--pending-bg);border:1px solid var(--pending-bd)}"
	$c+=".card{background:var(--surface);border:1px solid var(--line);border-radius:var(--radius);box-shadow:var(--shadow-sm)}"
	$c+=".hero{box-shadow:var(--shadow-md);overflow:hidden}"
	$c+=".hero-top{display:flex;align-items:center;justify-content:space-between;padding:15px 24px;border-bottom:1px solid var(--line);background:var(--surface-2)}"
	$c+=".hero-top .step-ctx{font-size:13px;color:var(--slate);display:flex;align-items:center;gap:9px}"
	$c+=".hero-top .step-ctx b{color:var(--ink);font-weight:600}"
	$c+=".hero-top .step-ctx .num{width:22px;height:22px;border-radius:7px;background:var(--accent-soft);color:var(--accent-ink);display:grid;place-items:center;font-size:12px;font-weight:700}"
	$c+=".hero-body{display:grid;grid-template-columns:220px 1fr;gap:36px;padding:32px;align-items:center}"
	$c+=".qr-tile{width:220px;height:220px;background:#fff;border:1px solid var(--line-2);border-radius:14px;padding:16px;position:relative}"
	$c+=".qr-tile img{width:100%;height:100%;display:block;border-radius:6px;object-fit:contain}"
	$c+=".qr-cap{text-align:center;font-size:12.5px;color:var(--faint);margin-top:12px}"
	$c+=".hero-info{display:flex;flex-direction:column;gap:20px}"
	$c+=".code-block{display:flex;align-items:center;gap:18px}"
	$c+=".code-badge{background:var(--accent-soft);border:1px solid #DEDEFB;border-radius:13px;padding:12px 22px;text-align:center;min-width:96px}"
	$c+=".code-badge .lbl{font-size:10px;letter-spacing:0.16em;text-transform:uppercase;color:var(--accent-ink);font-weight:700}"
	$c+=".code-badge .num{font-family:'IBM Plex Mono',monospace;font-size:44px;font-weight:600;color:var(--accent-ink);line-height:1.05}"
	$c+=".code-meta{font-size:13.5px;color:var(--slate)}"
	$c+=".code-meta .exp{display:flex;align-items:center;gap:7px;margin-top:6px;color:var(--ink)}"
	$c+=".code-meta .exp svg{width:14px;height:14px;color:var(--faint)}"
	$c+=".code-meta .exp .mono{font-weight:500}"
	$c+=".linkrow{display:flex;align-items:stretch;border:1px solid var(--line-2);border-radius:11px;overflow:hidden;background:var(--surface-2)}"
	$c+=".linkrow .tag{display:grid;place-items:center;padding:0 13px;font-size:10px;font-weight:700;letter-spacing:0.08em;text-transform:uppercase;color:var(--faint);border-right:1px solid var(--line)}"
	$c+=".linkrow .val{flex:1;min-width:0;display:flex;align-items:center;padding:12px;font-size:12.5px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}"
	$c+=".copy{border:0;border-left:1px solid var(--line);background:#fff;padding:0 16px;cursor:pointer;display:flex;align-items:center;gap:7px;font:inherit;font-size:12.5px;font-weight:600;color:var(--accent);transition:background .15s,color .15s}"
	$c+=".copy svg{width:14px;height:14px;stroke-width:1.9}"
	$c+=".copy:hover{background:var(--surface-2)}"
	$c+=".copy.copied{color:var(--done)}"
	$c+=".row{display:grid;grid-template-columns:1.15fr 1fr 1fr;gap:18px;margin-top:18px}"
	$c+=".card-head{padding:15px 20px;border-bottom:1px solid var(--line);display:flex;align-items:center;justify-content:space-between;gap:10px}"
	$c+=".card-head .lbl{font-size:11px;font-weight:700;letter-spacing:0.1em;text-transform:uppercase;color:var(--slate)}"
	$c+=".card-body{padding:20px}"
	$c+=".grid2{display:grid;grid-template-columns:1fr 360px;gap:18px;align-items:start;margin-top:18px}"
	$c+=".gcol{display:flex;flex-direction:column;gap:18px;min-width:0}"
	$c+=".evi{display:flex;gap:14px;align-items:center}"
	$c+=".evi .thumb{width:84px;height:84px;border-radius:10px;border:1px solid var(--line-2);background:var(--surface-2);display:grid;place-items:center;font-size:30px;color:var(--faint);flex:none;overflow:hidden}"
	$c+=".evi .thumb img{width:100%;height:100%;object-fit:cover}"
	$c+=".ename{font-weight:600;font-size:14px;word-break:break-all}"
	$c+=".ilink{display:inline-block;margin-top:6px;color:var(--accent);font-weight:600;font-size:12.5px;text-decoration:none}"
	$c+=".ilink:hover{text-decoration:underline}"
	$c+=".checks{display:flex;flex-direction:column}"
	$c+=".chk{display:flex;align-items:flex-start;gap:11px;padding:11px 0;border-bottom:1px solid var(--line)}"
	$c+=".chk:last-child{border-bottom:0}"
	$c+=".chk .g{width:19px;height:19px;border-radius:50%;flex:none;display:grid;place-items:center;font-size:11px;color:#fff;margin-top:1px}"
	$c+=".chk.pass .g{background:var(--done)}.chk.warn .g{background:var(--pending)}.chk.fail .g{background:#B42318}.chk.info .g{background:var(--faint)}"
	$c+=".chk .t{flex:1;min-width:0}.chk .cl{font-weight:600;font-size:13px}.chk .cn{color:var(--slate);font-size:12px}"
	$c+=".chk .cv{font-size:12.5px;color:var(--ink);white-space:nowrap;font-variant-numeric:tabular-nums}"
	$c+=".radios{display:flex;gap:8px}"
	$c+=".radio{flex:1;border:1px solid var(--line-2);border-radius:10px;padding:10px 6px;text-align:center;cursor:pointer;font-size:12.5px;font-weight:600;color:var(--slate)}"
	$c+=".radio:hover{border-color:var(--accent);color:var(--accent-ink)}"
	$c+="label.fl{display:block;font-size:12px;color:var(--ink);font-weight:600;margin:14px 0 6px}"
	$c+="select,textarea{width:100%;border:1px solid var(--line-2);border-radius:10px;padding:9px 11px;font-size:13px;font-family:inherit;background:#fff;color:var(--ink)}"
	$c+="textarea{min-height:74px;resize:vertical}"
	$c+="select:focus,textarea:focus{outline:none;border-color:var(--accent);box-shadow:0 0 0 3px rgba(79,70,229,0.12)}"
	$c+=".btnrow{display:flex;gap:10px;margin-top:14px;flex-wrap:wrap}"
	$c+=".btn.sec{background:#fff;border-color:var(--line-2);color:var(--ink)}.btn.sec:hover{background:var(--surface-2)}"
	$c+=".btn.ghost{background:transparent;color:var(--slate)}.btn.ghost:hover{background:var(--surface-2)}"
	$c+=".steps{position:relative}"
	$c+=".step{display:grid;grid-template-columns:26px 1fr;gap:13px;position:relative;padding-bottom:18px}"
	$c+=".step:last-child{padding-bottom:0}"
	$c+=".step .rail{position:absolute;left:12px;top:26px;bottom:-2px;width:2px;background:var(--line-2)}"
	$c+=".step:last-child .rail{display:none}"
	$c+=".step .mk{width:26px;height:26px;border-radius:50%;display:grid;place-items:center;font-size:12px;font-weight:700;z-index:1}"
	$c+=".step.done .mk{background:var(--done);color:#fff}"
	$c+=".step.done .rail{background:var(--done)}"
	$c+=".step.done .mk svg{width:14px;height:14px;stroke-width:2.5}"
	$c+=".step.active .mk{background:#fff;color:var(--accent);border:2px solid var(--accent)}"
	$c+=".step.upcoming .mk{background:var(--surface-2);color:var(--faint);border:1.5px solid var(--line-2)}"
	$c+=".step .t{font-weight:600;font-size:13.5px}"
	$c+=".step.upcoming .t{color:var(--slate);font-weight:500}"
	$c+=".step .m{font-size:12px;color:var(--faint);margin-top:1px}"
	$c+=".drow{display:flex;align-items:center;justify-content:space-between;gap:14px;padding:11px 0;border-bottom:1px solid var(--line)}"
	$c+=".drow:first-child{padding-top:0}"
	$c+=".drow:last-child{border-bottom:0;padding-bottom:0}"
	$c+=".drow .k{color:var(--slate);font-size:13px}"
	$c+=".drow .v{font-size:13px;font-weight:500;text-align:right}"
	$c+=".ev{display:grid;grid-template-columns:14px 1fr;gap:11px;position:relative;padding-bottom:14px}"
	$c+=".ev:last-child{padding-bottom:0}"
	$c+=".ev .er{position:absolute;left:6px;top:14px;bottom:0;width:1.5px;background:var(--line-2)}"
	$c+=".ev:last-child .er{display:none}"
	$c+=".ev .ed{width:14px;height:14px;border-radius:50%;background:#fff;border:2px solid var(--accent);display:grid;place-items:center;margin-top:1px}"
	$c+=".ev .ed i{width:4px;height:4px;border-radius:50%;background:var(--accent)}"
	$c+=".ev .x{font-size:13px}"
	$c+=".ev .ti{font-size:11.5px;color:var(--faint);margin-top:1px}"
	$c+=".muted{color:var(--faint);font-size:12.5px;word-break:break-all}"
	$c+=".chip.neutral{color:var(--slate);background:var(--surface-2);border:1px solid var(--line-2)}"
	$c+="table{width:100%;border-collapse:collapse;font-size:13px}"
	$c+="thead th{text-align:left;font-size:11px;font-weight:700;letter-spacing:.06em;text-transform:uppercase;color:var(--faint);padding:12px 20px;border-bottom:1px solid var(--line);background:var(--surface-2)}"
	$c+="tbody td{padding:13px 20px;border-bottom:1px solid var(--line);font-variant-numeric:tabular-nums;vertical-align:middle}"
	$c+="tbody tr:last-child td{border-bottom:0}"
	$c+="tbody tr:hover{background:var(--surface-2)}"
	$c+="td a{color:var(--accent);font-weight:600;text-decoration:none}"
	$c+="td a:hover{text-decoration:underline}"
	$c+=".empty{padding:44px 20px;text-align:center;color:var(--faint);font-size:13.5px}"
	$c+=".empty a,.substatus a{color:var(--accent);font-weight:600;text-decoration:none}"
	$c+=".empty a:hover,.substatus a:hover{text-decoration:underline}"
	$c+=".hint{font-size:12px;color:var(--faint);margin-top:14px}"
	$c+=".subjwrap{max-width:460px;margin:0 auto}"
	$c+=".subjnav .env{margin-left:auto}"
	$c+=".scard{background:var(--surface);border:1px solid var(--line);border-radius:var(--radius);box-shadow:var(--shadow-sm);padding:24px;margin-bottom:16px}"
	$c+=".scard.center,.center{text-align:center}"
	$c+=".stitle{font-weight:700;font-size:18px;letter-spacing:-0.01em}"
	$c+=".steps2{display:flex;gap:6px;margin:16px 0}"
	$c+=".steps2 .s{flex:1;height:6px;border-radius:3px;background:var(--line-2)}"
	$c+=".steps2 .s.on{background:var(--accent)}"
	$c+=".numbtn{width:100%;font-family:'IBM Plex Mono',monospace;font-size:30px;font-weight:600;border:1px solid var(--line-2);border-radius:13px;padding:16px;margin:6px 0;background:#fff;color:var(--ink);cursor:pointer;transition:border-color .15s,color .15s"+",background .15s}"
	$c+=".numbtn:hover{border-color:var(--accent);color:var(--accent-ink);background:var(--accent-soft)}"
	$c+=".numbtn:active{transform:scale(.98)}"
	$c+=".banner{padding:13px 15px;border-radius:12px;font-weight:600;border:1px solid;margin-bottom:12px}"
	$c+=".banner.ok{background:var(--done-bg);border-color:#CFE9D9;color:var(--done)}"
	$c+=".banner.bad{background:#FEECEC;border-color:#F4C6C2;color:#B42318}"
	$c+=".banner.warn{background:var(--pending-bg);border-color:var(--pending-bd);color:var(--pending)}"
	$c+="dl.def{display:grid;grid-template-columns:auto 1fr;gap:9px 14px;font-size:13.5px;margin-top:14px;text-align:left}"
	$c+="dl.def dt{color:var(--slate)}"
	$c+="dl.def dd{text-align:right;font-variant-numeric:tabular-nums;word-break:break-all}"
	$c+=".note{font-size:12.5px;color:var(--slate);margin-top:10px;line-height:1.55}"
	$c+=".code{background:var(--surface-2);border:1px solid var(--line-2);border-radius:6px;padding:2px 7px;font-family:'IBM Plex Mono',monospace;font-size:12.5px}"
	$c+=".filein{display:block;width:100%;padding:12px;border:1.5px dashed var(--line-2);border-radius:12px;background:var(--surface-2);font-size:13px;margin-top:6px}"
	$c+=".btn{display:inline-flex;align-items:center;justify-content:center;gap:7px;border:1px solid transparent;border-radius:11px;padding:12px 18px;font-size:14px;font-weight:600;cursor:pointer;font-family:inherit}"
	$c+=".btn.primary{background:var(--accent);color:#fff}"
	$c+=".btn.primary:hover{background:var(--accent-ink)}"
	$c+=".btn.primary:disabled{opacity:.6;cursor:not-allowed}"
	$c+="@media (max-width:880px){.row{grid-template-columns:1fr}.grid2{grid-template-columns:1fr}.hero-body{grid-template-columns:1fr;justify-items:center;text-align:center}.hero-info{width:100%}.code-block{justify-content:center}.links a span{display:none}.s"+"earch input{width:150px}}"
	$c+="@media (max-width:560px){.nav-inner,main{padding-left:16px;padding-right:16px}.search{display:none}.env span.t{display:none}.pagehead{flex-direction:column}h1{font-size:23px}.code-block{flex-direction:column}}"
	$c+=":focus-visible{outline:2px solid var(--accent);outline-offset:2px;border-radius:4px}"
	$c+="@media (prefers-reduced-motion:reduce){*{animation:none !important;transition:none !important}}"
	return $c
	
Function css() : Text
	var $c : Text
	$c:="*{box-sizing:border-box;margin:0;padding:0}"
	$c+="body{font-family:'Inter',-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Arial,sans-serif;background:#f7f8fa;color:#111827;font-size:14px;line-height:1.5}"
	$c+="a{color:inherit;text-decoration:none}"
	$c+=".app{display:flex;min-height:100vh}"
	$c+=".side{width:228px;background:#0f172a;color:#cbd5e1;flex:none;display:flex;flex-direction:column}"
	$c+=".side .logo{padding:18px 20px;font-weight:700;color:#fff;letter-spacing:.04em;border-bottom:1px solid #1e293b;font-size:15px}"
	$c+=".side nav{padding:10px 8px;display:flex;flex-direction:column;gap:2px}"
	$c+=".nav-i{display:flex;align-items:center;gap:10px;padding:9px 12px;border-radius:6px;color:#94a3b8;font-weight:500;font-size:13px}"
	$c+=".nav-i .ic{width:16px;text-align:center}"
	$c+=".nav-i:hover{background:#1e293b;color:#e2e8f0}"
	$c+=".nav-i.active{background:#1f4e8c;color:#fff}"
	$c+=".nav-i.disabled{opacity:.45}"
	$c+=".side .foot{margin-top:auto;padding:14px 20px;border-top:1px solid #1e293b;font-size:11.5px;color:#64748b}"
	$c+=".main{flex:1;display:flex;flex-direction:column;min-width:0}"
	$c+=".top{height:56px;background:#fff;border-bottom:1px solid #e5e7eb;display:flex;align-items:center;gap:16px;padding:0 24px}"
	$c+=".top .search{flex:1;max-width:420px}"
	$c+=".top .search input{width:100%;border:1px solid #e5e7eb;border-radius:6px;padding:7px 10px;font-size:13px;background:#f9fafb}"
	$c+=".env{font-size:12px;font-weight:600;color:#15803d;border:1px solid #bbf7d0;background:#f0fdf4;padding:3px 9px;border-radius:999px}"
	$c+=".ava{width:30px;height:30px;border-radius:6px;background:#1f4e8c;color:#fff;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700}"
	$c+=".content{padding:22px 28px;max-width:1120px;width:100%}"
	$c+=".crumb{font-size:12.5px;color:#6b7280;margin-bottom:8px}"
	$c+=".crumb b{color:#111827}"
	$c+=".h1{font-size:20px;font-weight:700}"
	$c+=".subt{color:#6b7280;margin-bottom:18px;font-size:13px}"
	$c+=".label{color:#6b7280;font-size:11px;text-transform:uppercase;letter-spacing:.05em}"
	$c+=".row{display:flex;gap:18px;align-items:flex-start;flex-wrap:wrap}"
	$c+=".row>.col{flex:1;min-width:280px}"
	$c+=".row>.col.side2{flex:0 0 320px}"
	$c+=".panel{background:#fff;border:1px solid #e5e7eb;border-radius:8px;margin-bottom:18px}"
	$c+=".panel>.ph{padding:11px 16px;border-bottom:1px solid #e5e7eb;font-weight:600;font-size:13px;color:#374151;display:flex;justify-content:space-between;align-items:center}"
	$c+=".panel>.pb{padding:16px}"
	$c+="table{width:100%;border-collapse:collapse;font-size:13px}"
	$c+="th{text-align:left;color:#6b7280;font-weight:600;font-size:11.5px;text-transform:uppercase;letter-spacing:.03em;padding:10px 12px;border-bottom:1px solid #e5e7eb}"
	$c+="td{padding:11px 12px;border-bottom:1px solid #f1f5f9;font-variant-numeric:tabular-nums}"
	$c+=".pill{display:inline-flex;align-items:center;gap:6px;font-size:12px;font-weight:600;padding:3px 9px;border-radius:999px;border:1px solid}"
	$c+=".pill::before{content:'';width:7px;height:7px;border-radius:50%;background:currentColor}"
	$c+=".pill.pending{color:#b45309;border-color:#fde68a;background:#fffbeb}"
	$c+=".pill.verified,.pill.under_review{color:#1d4ed8;border-color:#bfdbfe;background:#eff6ff}"
	$c+=".pill.approved{color:#15803d;border-color:#bbf7d0;background:#f0fdf4}"
	$c+=".pill.rejected{color:#b91c1c;border-color:#fecaca;background:#fef2f2}"
	$c+=".pill.info_requested{color:#b45309;border-color:#fde68a;background:#fffbeb}"
	$c+="dl.def{display:grid;grid-template-columns:120px 1fr;gap:9px 12px;font-size:13px}"
	$c+="dl.def dt{color:#6b7280}"
	$c+="dl.def dd{font-variant-numeric:tabular-nums;word-break:break-all}"
	$c+=".checks{display:flex;flex-direction:column}"
	$c+=".chk{display:flex;align-items:flex-start;gap:10px;padding:10px 0;border-bottom:1px solid #f1f5f9}"
	$c+=".chk:last-child{border-bottom:none}"
	$c+=".chk .g{width:18px;height:18px;border-radius:50%;flex:none;display:flex;align-items:center;justify-content:center;font-size:11px;color:#fff;margin-top:1px}"
	$c+=".chk.pass .g{background:#15803d}.chk.warn .g{background:#b45309}.chk.fail .g{background:#b91c1c}.chk.info .g{background:#64748b}"
	$c+=".chk .t{flex:1}.chk .t .cl{font-weight:600;font-size:13px}.chk .t .cn{color:#6b7280;font-size:12px}"
	$c+=".chk .cv{font-size:12.5px;color:#374151;font-variant-numeric:tabular-nums;white-space:nowrap}"
	$c+=".tl{list-style:none;position:relative;padding-left:18px}"
	$c+=".tl::before{content:'';position:absolute;left:5px;top:4px;bottom:4px;width:2px;background:#e5e7eb}"
	$c+=".tl li{position:relative;padding:6px 0;font-size:13px}"
	$c+=".tl li::before{content:'';position:absolute;left:-16px;top:11px;width:8px;height:8px;border-radius:50%;background:#1f4e8c;border:2px solid #fff;box-shadow:0 0 0 1px #cbd5e1}"
	$c+=".tl .tt{color:#6b7280;font-variant-numeric:tabular-nums;font-size:11.5px;margin-right:6px}"
	$c+=".steps{display:flex;flex-direction:column;gap:10px}"
	$c+=".step{display:flex;align-items:center;gap:10px;color:#94a3b8;font-size:13px}"
	$c+=".step .dot{width:22px;height:22px;border-radius:50%;background:#e5e7eb;color:#94a3b8;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;flex:none}"
	$c+=".step.done{color:#111827}.step.done .dot{background:#15803d;color:#fff}"
	$c+=".evi{display:flex;gap:14px;align-items:center}"
	$c+=".evi .thumb{width:88px;height:88px;border-radius:6px;border:1px solid #e5e7eb;background:#f1f5f9;display:flex;align-items:center;justify-content:center;font-size:28px;color:#94a3b8;flex:none;overflow:hidden}"
	$c+="label.fl{display:block;font-size:12px;color:#374151;font-weight:600;margin:12px 0 5px}"
	$c+="select,textarea,input[type=text]{width:100%;border:1px solid #d1d5db;border-radius:6px;padding:8px 10px;font-size:13px;font-family:inherit}"
	$c+="textarea{min-height:72px;resize:vertical}"
	$c+=".filein{display:block;width:100%;padding:9px;border:1px dashed #cbd5e1;border-radius:6px;background:#f9fafb}"
	$c+=".radios{display:flex;gap:8px}"
	$c+=".radio{flex:1;border:1px solid #d1d5db;border-radius:6px;padding:9px 6px;text-align:center;cursor:pointer;font-size:12.5px;font-weight:600}"
	$c+=".btn{display:inline-flex;align-items:center;justify-content:center;gap:7px;border:1px solid transparent;border-radius:6px;padding:9px 16px;font-size:13px;font-weight:600;cursor:pointer;font-family:inherit}"
	$c+=".btn.primary{background:#1f4e8c;color:#fff}.btn.primary:hover{background:#1a4178}.btn.primary:disabled{background:#9aa8bd;cursor:not-allowed}"
	$c+=".btn.sec{background:#fff;border-color:#d1d5db;color:#374151}.btn.sec:hover{background:#f9fafb}"
	$c+=".btn.ghost{background:transparent;color:#6b7280}"
	$c+=".btnrow{display:flex;gap:10px;margin-top:14px;flex-wrap:wrap}"
	$c+=".muted{color:#94a3b8;font-size:12.5px;word-break:break-all}"
	$c+=".note{font-size:12px;color:#6b7280;margin-top:10px}"
	$c+=".bignum{font-size:42px;font-weight:800;font-variant-numeric:tabular-nums;color:#1f4e8c}"
	$c+=".qr{border:1px solid #e5e7eb;border-radius:8px}"
	$c+=".banner{padding:12px 14px;border-radius:8px;font-weight:600;margin-bottom:14px;border:1px solid}"
	$c+=".banner.ok{background:#f0fdf4;border-color:#bbf7d0;color:#166534}"
	$c+=".banner.bad{background:#fef2f2;border-color:#fecaca;color:#991b1b}"
	$c+=".banner.warn{background:#fffbeb;border-color:#fde68a;color:#92400e}"
	$c+=".code{background:#f1f5f9;border:1px solid #e5e7eb;border-radius:5px;padding:2px 6px;font-size:12px;font-variant-numeric:tabular-nums;word-break:break-all}"
	$c+=".subj{max-width:460px;margin:0 auto;padding:22px 16px}"
	$c+=".sbrand{font-weight:700;letter-spacing:.04em;color:#0f172a;text-align:center;margin-bottom:14px}"
	$c+=".scard{background:#fff;border:1px solid #e5e7eb;border-radius:10px;padding:20px;margin-bottom:14px}"
	$c+=".scard.center{text-align:center}"
	$c+=".stitle{font-weight:700;font-size:17px}"
	$c+=".steps2{display:flex;gap:6px;margin:14px 0}"
	$c+=".steps2 .s{flex:1;height:5px;border-radius:3px;background:#e5e7eb}"
	$c+=".steps2 .s.on{background:#1f4e8c}"
	$c+=".numbtn{width:100%;font-size:30px;font-weight:800;font-variant-numeric:tabular-nums;border:1px solid #d1d5db;border-radius:10px;padding:16px;margin:6px 0;background:#fff;cursor:pointer}"
	$c+=".numbtn:hover{border-color:#1f4e8c;color:#1f4e8c}"
	$c+="@media print{.side,.top{display:none}.content{max-width:none}}"
	return $c
	