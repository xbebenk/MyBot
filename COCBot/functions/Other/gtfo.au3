
Func kasihkakigan()

Global $kakienable = 1
Global $makskaki = 2

local $xcc, $ycc, $xdonasi, $ydonasi, $xdapetdonasi, $ydapetdonasi, $test
$xcc = 404
$ycc = 347

$xdonasi = 490
$ydonasi = 443

$xdapetdonasi = 609
$ydapetdonasi = 443

local $kk, $cekwarna, $kenakaki, $scroll, $donasi, $dapetdonasi, $loopcount, $num, $a1

SetLog("Kasih kaki gan...", $COLOR_RED)

;Click($xcc, $ycc) ; klik kastil
;_Sleep(2000)

;Click(481,655); klik lambang kastil
;_Sleep(2000)

Local $hClone = _GDIPlus_BitmapCloneArea($g_hBitmap, $xdonasi, $ydonasi, 66,14, $GDIP_PXF24RGB)
_GDIPlus_ImageSaveToFile($hClone, @ScriptDir & "\testtt.png")
$donasi = getArmyCampCapa($xdonasi,$ydonasi)
$dapetdonasi = getArmyCampCapa($xdapetdonasi,$ydapetdonasi)

SetLog("donasi = " & $donasi & " dapetdonasi = " & $dapetdonasi, $COLOR_RED)
_Sleep(1000)
$test = GUICtrlRead($g_hTxtTestFindButton)
ClickDrag(420, 500, 420, $test, 2000)

;$donasi = getArmyCampCapa($xdonasi,$ydonasi)
;$dapetdonasi = getArmyCampCapa($xdapetdonasi,$ydapetdonasi)
;
;SetLog("donasi = " & $donasi & " dapetdonasi = " & $dapetdonasi, $COLOR_RED)

;SetLog("Kelar gan...", $COLOR_RED)
EndFunc





Func GTFO()

Global $g_hchkGTFO = 1
Global $cmbgtfo = 20

	  Click(1, 1, 1, 1000)
	  Local  $test, $Scroll,$len, $kick_y, $kicked = 0,$kicklimit, $mDonated, $mReceived, $Count = 1, $loopcount, $new, $p1, $p2,$lastNum, $lastNumCheck, $cp, $sNum
	  $p1 = 533 ; 483 FOR MAXLVL CLAN CASTLE, 533 FOR NORMAL CLAN CASTLE,  577 FOR UNDER UPGRADE CLAN CASTLE
	  $p2 = 660
	  $len = 0

	  $kicklimit=  2
		;If GUICtrlRead($g_hchkGTFO) = 1 Then
		If $g_hchkGTFO = 1 Then
			SetLog("Started Kicking", $COLOR_RED)
	  Else
		 Return
	  EndIf

	Click(404, 347) ; click clan castle
	_Sleep(2000)
	Click(481,655); click clan button
	_Sleep(2000)

	  While $kicked < $kicklimit
		 ;Click(1, 1, 1, 1000)
		 If $g_hchkGTFO = 1 Then
			;If _Sleep(20) Then ExitLoop
			;Click(404, 347) ; click clan castle
			;If _Sleep(500) Then ExitLoop
			$test = GUICtrlRead($g_hTxtTestFindButton)
			$new = _PixelSearch(490, 680, 568, 698, Hex($test, 6),20)
			SetLog("New = " & $new[0], $COLOR_RED)
			If IsArray($new) Then
			   $p1 = $new[0]
			Else
			   SetLog("Error: Unable to Start Kicking", $COLOR_RED)
			   Return
			EndIf
			SetLog("p1 = " & $p1, $COLOR_RED)
			$loopcount = 0
		   ;Click($p1, $p2)
		   ;Click(481,655)

			;While _ColorCheck( _GetPixelColor(60, 350, True), Hex(0x65B010, 6), 20) == False
			;   If _Sleep(100) Then ExitLoop
			;   $loopcount += 1
			;   If $loopcount >= 50 Then
			;	   $loopcount = 0
			;	    Click(1, 1, 1, 1000)
			;	   SetLog("Unable to Load Clan Page.", $COLOR_RED)
			;	   Return
			;   EndIf
			;WEnd
			Local $KickPosX = -1, $KickPosX1, $KickPosX2
			Local $KickPosY = 0, $KickPosY1
			$Scroll = 0
			$cp = 110
			$len = 0
			While 1
			   SetLog("Capture. cp: " & $cp , $COLOR_ORANGE)
			   _CaptureRegion(190, $cp, 220, 640)
			   $new = _PixelSearch(200, $cp, 210, 670, Hex(0xE73838, 6),20)
			   ;SetLog("_PixelSearch(200," & $cp & ",210, 670, Hex(0xE73838, 6),20)", $COLOR_ORANGE)
			   If IsArray($new) Then
				  $KickPosX = $new[0]
				  $KickPosY = $new[1]
				  SetLog("$KickPosX = " & $KickPosX, $COLOR_ORANGE)
				  SetLog("$KickPosY = " & $KickPosY, $COLOR_ORANGE)

				  $KickPosX1 = $KickPosX + 281
				  $KickPosX2 = $KickPosX + 400
				  $KickPosY1 = $KickPosY - 10

				  $mDonated = getArmyCampCapa($new[0]+281,$new[1]-10)
				  SetLog("mDonated ->> KickPosX = " & $KickPosX1 & "," & $KickPosY1, $COLOR_ORANGE)
				  $mReceived = getArmyCampCapa($new[0]+400,$new[1]-10)
				  SetLog("mReceived ->> KickPosX = " & $KickPosX2 & "," & $KickPosY1, $COLOR_ORANGE)
				  $sNum = getTrophyVillageSearch($new[0]-180,$new[1]-18)
				  If $g_iDebugSetlog = 1 Then SetLog("Check For To Kick Members", $COLOR_RED)
				  If $g_iDebugSetlog = 1 Then SetLog($sNum & " # x:" & $new[0] & " y:"  & $new[1], $COLOR_RED)
					SetLog("Player #" & $sNum & "  Donated : " & $mDonated &  " - Received : " & $mReceived & " has been kicked out", $COLOR_RED)

				 If $mDonated >0 or $mReceived > 35 or $mReceived = 26  or $mReceived = 20 or $mReceived = 25 or $mReceived = 10 or $mReceived = 15 then
;~ 				 ;If $mDonated >0 then
					 Click($new[0], $new[1])
					 If _Sleep(250) Then ExitLoop
					 If $new[1] > 615 Then
						;$kick_y = 700
					 Else
						;$kick_y = $new[1] + 70
					 EndIf
					 ;Click($new[0] + 300, $kick_y) ; kick
					 If _Sleep(250) Then ExitLoop
					 ;Click(520, 240)
					 If _Sleep(250) Then ExitLoop
					 $kicked += 1
					 SetLog("Player #" & $sNum & "  Donated : " & $mDonated &  " - Received : " & $mReceived & " has been kicked out", $COLOR_RED)
					 If _Sleep(250) Then ExitLoop
					 ExitLoop
					 Return
				 Else
					 $cp = $new[1]  + 20
;~ 					 ExitLoop
				 EndIf
				;Else
				;  if $Scroll > 5 then
				;	  If $g_iDebugSetlog = 1 Then SetLog("Kicking bottom members", $COLOR_RED)
				;	  If $KickPosX > 0 Then
				;		If $g_iDebugSetlog = 1 Then SetLog($sNum & " # x:" & $KickPosX & " y:"  & $KickPosY, $COLOR_RED)
				;		Click($KickPosX, $KickPosY)
				;		If _Sleep(250) Then ExitLoop
				;		If $KickPosY  > 615 Then
				;		   $kick_y = 700
				;		Else
				;		   $kick_y = $KickPosY + 70
				;		EndIf
				;		Click($KickPosX + 300, $kick_y) ; kick
				;		If _Sleep(250) Then ExitLoop
				;		Click(520, 240)
				;		If _Sleep(250) Then ExitLoop
				;		$kicked += 1
				;		SetLog("Player #" & $sNum & "  Donated : " & $mDonated &  " - Received : " & $mReceived & " has been kicked out (Bottom)", $COLOR_RED)
				;	 Else
				;		If $g_iDebugSetlog = 1 Then SetLog("no members to kick", $COLOR_RED)
				;	 EndIf
				;	 ExitLoop 2
				;  Else
				;	 ClickDrag(430,665,430,115,500)
				;	 Click(50,80)
				;	 ClickDrag(430,175,430,174,500)
				;	 Click(50,80)
				;	 $cp = 110
				;	 If $g_iDebugSetlog = 1 Then SetLog("Page Scroll : " & $Scroll, $COLOR_RED)
				;	 $Scroll = $Scroll + 1
				;  EndIf
			   EndIf
			WEnd



		 Else
			SetLog("Enable Kicking First", $COLOR_RED)
			Return
		 EndIf
		 Click(1, 1, 1, 1000)
	  WEnd

	  SetLog("Finished Kicking", $COLOR_RED)
	  Click(1, 1, 1, 2000)
   EndFunc