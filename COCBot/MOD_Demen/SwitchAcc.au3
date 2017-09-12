; #FUNCTION# ====================================================================================================================
; Name ..........: Switch CoC Account
; Description ...: This file contains the Sequence that runs all MBR Bot
; Author ........: DEMEN (based on original code & idea of NDTHUAN)
; Modified ......:
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2016
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

Func InitiateSwitchAcc() ; Checking profiles setup in Mybot, First matching CoC Acc with current profile, Reset all Timers relating to Switch Acc Mode.

	$ProfileList = _GUICtrlComboBox_GetListArray($g_hCmbProfile)
	$nTotalProfile = _Min(8, _GUICtrlComboBox_GetCount($g_hCmbProfile))
	$nCurProfile = _GUICtrlComboBox_GetCurSel($g_hCmbProfile) + 1

	$aActiveProfile = _ArrayFindAll($aProfileType, $eActive)
	$aDonateProfile = _ArrayFindAll($aProfileType, $eDonate)

	Setlog($nTotalProfile & " profiles available")

	For $i = 0 To _Min($nTotalProfile - 1, 7)
		Switch $aProfileType[$i]
			Case $eActive
				Setlog("Profile [" & $i + 1 & "]: " & $ProfileList[$i + 1] & " - Active - Match with Account [" & $aMatchProfileAcc[$i] & "]")
			Case $eDonate
				Setlog("Profile [" & $i + 1 & "]: " & $ProfileList[$i + 1] & " - Donate - Match with Account [" & $aMatchProfileAcc[$i] & "]")
			Case Else
				Setlog("Profile [" & $i + 1 & "]: " & $ProfileList[$i + 1] & " - Idle   - Match with Account [" & $aMatchProfileAcc[$i] & "]")
		EndSwitch
	Next

	If $icmbTotalCoCAcc <> -1 Then
		$nTotalCoCAcc = $icmbTotalCoCAcc
		Setlog("Total CoC Account is declared: " & $nTotalCoCAcc)
	Else
		$nTotalCoCAcc = 8
		Setlog("Total CoC Account has not declared, default: " & $nTotalCoCAcc)
	EndIf

	; Locating CoC Accounts
	If _ArrayMax($aAccPosY) > 0 Then
		Local $MaxIdx = _ArrayMaxIndex($aAccPosY)
		For $i = 1 To $nTotalCoCAcc
			If $aAccPosY[$i - 1] <= 0 Then $aAccPosY[$i - 1] = $aAccPosY[$MaxIdx] + 73 * ($i - 1 - $MaxIdx)
			Setlog("  >>> Y-coordinate Acc No. " & $i & " is located at: " & $aAccPosY[$i - 1])
		Next
	EndIf

	$i = $nCurProfile
	While $aProfileType[$i - 1] = $eIdle Or $aProfileType[$i - 1] = $eNull ;	Current Profile is idle
		If $i < $nTotalProfile Then
			$i += 1
		Else
			$i = 1
		EndIf
		If $aProfileType[$i - 1] <> $eIdle And $aProfileType[$i - 1] <> $eNull Then
			Setlog("Try to avoid Idle Profile. Switching to Profile [" & $i & "] - CoC Acc [" & $aMatchProfileAcc[$i - 1] & "]")
			_GUICtrlComboBox_SetCurSel($g_hCmbProfile, $i - 1)
			cmbProfile()
			DisableGUI_AfterLoadNewProfile()
			ExitLoop
		EndIf
	WEnd

	$nCurProfile = _GUICtrlComboBox_GetCurSel($g_hCmbProfile) + 1

	For $i = 0 To _Min($nTotalProfile - 1, 7)
		$aTimerStart[$i] = 0
		$aTimerEnd[$i] = 0
		$aRemainTrainTime[$i] = 0
		$aUpdateRemainTrainTime[$i] = 0

		$g_aLabTimeAcc[$i] = 0
		$g_aLabTimerStart[$i] = 0
	Next

	If $aProfileType[$nCurProfile - 1] = $eActive Then
		GUICtrlSetData($g_lblTroopsTime[$nCurProfile - 1], "Looting")
		GUICtrlSetBkColor($g_lblTroopsTime[$nCurProfile - 1], $COLOR_GREEN)
		GUICtrlSetColor($g_lblTroopsTime[$nCurProfile - 1], $COLOR_WHITE)
	ElseIf $aProfileType[$nCurProfile - 1] = $eDonate Then
		GUICtrlSetData($g_lblTroopsTime[$nCurProfile - 1], "Donating")
		GUICtrlSetBkColor($g_lblTroopsTime[$nCurProfile - 1], $COLOR_GREEN)
		GUICtrlSetColor($g_lblTroopsTime[$nCurProfile - 1], $COLOR_WHITE)
	EndIf

	Setlog("Matching CoC Account with Bot Profile. Trying to Switch Account", $COLOR_BLUE)

	SwitchCOCAcc()
	If $bReMatchAcc = False Then runBot()

EndFunc   ;==>InitiateSwitchAcc

Func CheckWaitHero() ; get hero regen time remaining if enabled
	Local $iActiveHero
	Local $aHeroResult[3]
	$g_aiTimeTrain[2] = 0

	$aHeroResult = getArmyHeroTime("all")

	If @error Then
		Setlog("getArmyHeroTime return error, exit Check Hero's wait time!", $COLOR_RED)
		Return ; if error, then quit Check Hero's wait time
	EndIf

	If $aHeroResult = "" Then
		Setlog("You have no hero or bad TH level detection Pls manually locate TH", $COLOR_RED)
		Return
	EndIf

;	Setlog("Getting Hero's recover time, King: " & $aHeroResult[0] & " m, Queen: " & $aHeroResult[1] & " m, GW: " & $aHeroResult[2] & " m.")

	If _Sleep($DELAYRESPOND) Then Return
	If $aHeroResult[0] > 0 Or $aHeroResult[1] > 0 Or $aHeroResult[2] > 0 Then ; check if hero is enabled to use/wait and set wait time
		For $pTroopType = $eKing To $eWarden ; check all 3 hero
			For $pMatchMode = $DB To $g_iModeCount - 1 ; check all attack modes
				$iActiveHero = -1
				If IsSpecialTroopToBeUsed($pMatchMode, $pTroopType) And _
						BitOR($g_aiAttackUseHeroes[$pMatchMode], $g_aiSearchHeroWaitEnable[$pMatchMode]) = $g_aiAttackUseHeroes[$pMatchMode] Then ; check if Hero enabled to wait
					$iActiveHero = $pTroopType - $eKing ; compute array offset to active hero
				EndIf
				If $iActiveHero <> -1 And $aHeroResult[$iActiveHero] > 0 Then ; valid time?
					; check exact time & existing time is less than new time
					If $g_aiTimeTrain[2] < $aHeroResult[$iActiveHero] Then
						$g_aiTimeTrain[2] = $aHeroResult[$iActiveHero] ; use exact time
					EndIf
				EndIf
			Next
			If _Sleep($DELAYRESPOND) Then Return
		Next
	EndIf

;	Setlog("Hero recover wait time: " & $g_aiTimeTrain[2] & " minute(s)", $COLOR_BLUE)

EndFunc   ;==>CheckWaitHero

Func MinRemainTrainAcc($Writelog = True, $ExcludeProfile = 0) ; Check remain training time of all Active accounts and return the minimum remain training time

	If $ExcludeProfile = 0 Then
		$aRemainTrainTime[$nCurProfile - 1] = _ArrayMax($g_aiTimeTrain) ; remaintraintime of current account - in minutes
		$aTimerStart[$nCurProfile - 1] = TimerInit() ; start counting elapse of training time of current account
	EndIf

	For $i = 0 To $nTotalProfile - 1
		If $i = $ExcludeProfile - 1 Then ContinueLoop
		If $aProfileType[$i] = $eActive Then ;	Only check Active profiles
			If $aTimerStart[$i] <> 0 Then
				$aTimerEnd[$i] = Round(TimerDiff($aTimerStart[$i]) / 1000 / 60, 2) ; 	counting elapse of training time of an account from last army checking - in minutes
				$aUpdateRemainTrainTime[$i] = $aRemainTrainTime[$i] - $aTimerEnd[$i] ;   updated remain train time of Active accounts
				If $Writelog = True Then
					If $aUpdateRemainTrainTime[$i] >= 0 Then
						Setlog("Profile [" & $i + 1 & "] - " & $ProfileList[$i + 1] & " (Acc. " & $aMatchProfileAcc[$i] & ") will have full army in:" & $aUpdateRemainTrainTime[$i] & " minutes")
					Else
						Setlog("Profile [" & $i + 1 & "] - " & $ProfileList[$i + 1] & " (Acc. " & $aMatchProfileAcc[$i] & ") was ready:" & - $aUpdateRemainTrainTime[$i] & " minutes ago")
					EndIf
				EndIf
			Else ; for accounts first Run
				If $Writelog = True Then Setlog("Profile [" & $i + 1 & "] - " & $ProfileList[$i + 1] & " (Acc. " & $aMatchProfileAcc[$i] & ") has not been read its remain train time")
				$aUpdateRemainTrainTime[$i] = -999
			EndIf
		EndIf
	Next

	$nMinRemainTrain = _ArrayMax($aUpdateRemainTrainTime)
	For $i = 0 To $nTotalProfile - 1
		If $i = $ExcludeProfile - 1 Then ContinueLoop
		If $aProfileType[$i] = $eActive Then ;	Only check Active profiles
			If $aUpdateRemainTrainTime[$i] <= $nMinRemainTrain Then
				$nMinRemainTrain = $aUpdateRemainTrainTime[$i]
				$nNextProfile = $i + 1
			EndIf
		EndIf
	Next

	Return $nMinRemainTrain

EndFunc   ;==>MinRemainTrainAcc

Func SwitchProfile($SwitchCase) ; Switch profile (1 = Active, 2 = Donate, 4 = Stay , 5 = switching continuosly) - DEMEN

	$nCurProfile = _GUICtrlComboBox_GetCurSel($g_hCmbProfile) + 1

	Switch $SwitchCase
		Case $eActive
			Setlog("Switch to active Profile [" & $nNextProfile & "] - " & $ProfileList[$nNextProfile] & " (Acc. " & $aMatchProfileAcc[$nNextProfile - 1] & ")")
			_GUICtrlComboBox_SetCurSel($g_hCmbProfile, $nNextProfile - 1)
			cmbProfile()

		Case $eDonate
			$nNextProfile = $aDonateProfile[$DonateSwitchCounter] + 1
			Setlog("Switch to Profile [" & $nNextProfile & "] - " & $ProfileList[$nNextProfile] & " (Acc. " & $aMatchProfileAcc[$nNextProfile - 1] & ") for donating")
			_GUICtrlComboBox_SetCurSel($g_hCmbProfile, $nNextProfile - 1)
			$DonateSwitchCounter += 1
			cmbProfile()

		Case $eStay
			Setlog("Staying in this profile")

		Case $eContinuous
			Setlog("Switching to next account")
			$nNextProfile = 1
			If $nCurProfile < $nTotalProfile Then
				$nNextProfile = $nCurProfile + 1
			Else
				$nNextProfile = 1
			EndIf
			While $aProfileType[$nNextProfile - 1] = $eIdle Or $aProfileType[$nNextProfile - 1] = $eNull
				If $nNextProfile < $nTotalProfile Then
					$nNextProfile += 1
				Else
					$nNextProfile = 1
				EndIf
				If $aProfileType[$nNextProfile - 1] <> $eIdle And $aProfileType[$nNextProfile - 1] <> $eNull Then ExitLoop
			WEnd
			_GUICtrlComboBox_SetCurSel($g_hCmbProfile, $nNextProfile - 1)
			cmbProfile()
	EndSwitch

	If _Sleep(1000) Then Return

	If $SwitchCase <> $eStay Then DisableGUI_AfterLoadNewProfile()

	$nCurProfile = _GUICtrlComboBox_GetCurSel($g_hCmbProfile) + 1

EndFunc   ;==>SwitchProfile

Func UpdateTrainTimeStatus($sSwitch = "After")
	If $sSwitch = "Before" Then
		;Update Stats Label GUI before switching Profile
		If $aProfileType[$nCurProfile - 1] = $eDonate Then ; Set Gui Label for Donate or Looting CurrentAccount BackGround Color Green
			GUICtrlSetData($g_lblTroopsTime[$nCurProfile - 1], "Donate")
		ElseIf $aProfileType[$nCurProfile - 1] = $eActive Then
			GUICtrlSetData($g_lblTroopsTime[$nCurProfile - 1], Round($aUpdateRemainTrainTime[$nCurProfile - 1], 2))
		EndIf
		GUICtrlSetBkColor($g_lblTroopsTime[$nCurProfile - 1], $COLOR_YELLOW)
		GUICtrlSetColor($g_lblTroopsTime[$nCurProfile - 1], $COLOR_BLACK)
	Else
		;Update Stats Label GUI of new profile
		If $aProfileType[$nCurProfile - 1] = $eDonate Then ; Set Gui Label for Donate or Looting CurrentAccount BackGround Color Green
			GUICtrlSetData($g_lblTroopsTime[$nCurProfile - 1], "Donating")
		ElseIf $aProfileType[$nCurProfile - 1] = $eActive Then
			GUICtrlSetData($g_lblTroopsTime[$nCurProfile - 1], "Looting")
		EndIf
		GUICtrlSetBkColor($g_lblTroopsTime[$nCurProfile - 1], $COLOR_GREEN)
		GUICtrlSetColor($g_lblTroopsTime[$nCurProfile - 1], $COLOR_WHITE)
	EndIf
EndFunc   ;==>UpdateTrainTimeStatus

Func CheckSwitchAcc() ; Switch CoC Account with or without sleep combo - DEMEN

	Local $SwitchCase, $bReachAttackLimit

	SetLog("Start SwitchAcc")

	If IsMainPage() = False Then ClickP($aAway, 2, 250, "#0335") ; Sometimes the bot cannot open Army Overview Window, trying to click away first
	If IsMainPage() = False Then checkMainScreen() ; checkmainscreen (may restart CoC) if still fail to locate main page.
	getArmyTroopTime(True, False)

	If IsWaitforSpellsActive() Then
		getArmySpellTime()
	Else
		$g_aiTimeTrain[1] = 0
	EndIf

	If IsWaitforHeroesActive() Then
		CheckWaitHero()
	Else
		$g_aiTimeTrain[2] = 0
	EndIf

	ClickP($aAway, 1, 0, "#0000") ;Click Away

	$bReachAttackLimit = ($aAttackedCountSwitch[$nCurProfile - 1] <= $aAttackedCountAcc[$nCurProfile - 1] - 2)

	Local $iWaitTime = _ArrayMax($g_aiTimeTrain)
	Local $sLogSkip = ""
    If $aProfileType[$nCurProfile - 1] = $eActive And $iWaitTime <= $g_iTrainTimeToSkip And Not ($bReachAttackLimit) And Not $g_bWaitForCCTroopSpell Then
		If $iWaitTime > 0 Then $sLogSkip = "in " & Round($iWaitTime, 2) & " m"
		Setlog("Army is ready" & $sLogSkip & ", skip switching account")
		If _Sleep(500) Then Return

	Else
		If _ArrayMax($g_aiTimeTrain) <= 0 And $bReachAttackLimit Then Setlog("This account has attacked twice in a row, switching account")

		MinRemainTrainAcc()

		If $ichkSmartSwitch = 1 And _ArraySearch($aProfileType, $eActive) <> -1 Then ; Smart switch and there is at least 1 active profile
			If $nMinRemainTrain <= 1 Then
				If $nCurProfile <> $nNextProfile Then
					$SwitchCase = $eActive
				Else
					$SwitchCase = $eStay
				EndIf
				$DonateSwitchCounter = 0
			Else
				If $DonateSwitchCounter < UBound($aDonateProfile) Then
					$SwitchCase = $eDonate
				Else
					If $nCurProfile <> $nNextProfile Then
						$SwitchCase = $eActive
					ElseIf $nMinRemainTrain <= 3 Then
						$SwitchCase = $eStay
					Else
						setlog("Still " & Round($nMinRemainTrain, 2) & " min until army is ready. Other accounts may need donating.")
						$SwitchCase = $eContinuous
					EndIf
					$DonateSwitchCounter = 0
				EndIf
			EndIf
		Else
			$SwitchCase = $eContinuous
		EndIf

		If $SwitchCase <> $eStay Then
			If $aProfileType[$nCurProfile - 1] = $eActive And $g_bRequestTroopsEnable = True And $g_bCanRequestCC = True Then
				Setlog("Try Request troops before switching account", $COLOR_BLUE)
				RequestCC(True)
			EndIf
			UpdateTrainTimeStatus("Before") ;Update Stats Label GUI before switching Profile
			SwitchProfile($SwitchCase)
			UpdateTrainTimeStatus() ;Update Stats Label GUI of new profile
			If IsMainPage() = False Then checkMainScreen()
			SwitchCOCAcc()
		Else
			SwitchProfile($SwitchCase)
		EndIf

		If $ichkCloseTraining >= 1 And $nMinRemainTrain > 3 And $SwitchCase <> $eDonate And $SwitchCase <> $eContinuous Then
			checkMainScreen()
			VillageReport()
            UpdateLabStatus()
            UpdateHeroStatus()
			ReArm()
			If $g_bRequestTroopsEnable = True And $g_bCanRequestCC = True Then
				Setlog("Try Request troops before going to sleep", $COLOR_BLUE)
				RequestCC(True)
			EndIf
			PoliteCloseCoC()
			$g_abNotNeedAllTime[0] = 1
			$g_abNotNeedAllTime[1] = 1
			If $ichkCloseTraining = 2 Then CloseAndroid("SwitchAcc")
			EnableGuiControls() ; enable emulator menu controls
			SetLog("Enable emulator menu controls due long wait time!")
			If $ichkCloseTraining = 1 Then
				WaitnOpenCoC(($nMinRemainTrain - 1) * 60 * 1000, True)
			Else
				If _SleepStatus(($nMinRemainTrain - 1.5) * 60 * 1000) Then Return
				OpenAndroid()
				OpenCoC()
			EndIf

			SaveConfig()
			readConfig()
			applyConfig()
			DisableGuiControls()
			checkMainScreen()
		EndIf
		If $SwitchCase <> $eStay Then runBot()
	EndIf

EndFunc   ;==>CheckSwitchAcc

Func ForceSwitchAcc($AccType = $eDonate, $sSource = "")
	Local $SwitchCase
	If $sSource = "StayDonate" Then
		Setlog("Stay on Donation for: " & Round($nMinRemainTrain, 2) & "m until an Active Account is ready")
		If $DonateSwitchCounter >= UBound($aDonateProfile) Then $DonateSwitchCounter = 0
	EndIf

	If $AccType = $eDonate Then
		If UBound($aDonateProfile) > 0 And $DonateSwitchCounter < UBound($aDonateProfile) Then
			If $nCurProfile <> $aDonateProfile[$DonateSwitchCounter] + 1 Then
				$SwitchCase = $eDonate
			Else
				runBot()
			EndIf
			$eForceSwitch = $eDonate
		ElseIf $sSource = "SeachLimit" Then
			If MinRemainTrainAcc(False, $iProfileBeforeForceSwitch) > 0 Or UBound($aActiveProfile) = 1 Then
				$nNextProfile = $iProfileBeforeForceSwitch
				Setlog("Return to Active Profile: " & $ProfileList[$nNextProfile] & " to continue searching")
				$g_bRestart = True
			EndIf
			$SwitchCase = $eActive
			$eForceSwitch = $eNull
			$DonateSwitchCounter = 0
		Else
			$SwitchCase = $eActive
			MinRemainTrainAcc(False, $nCurProfile)
			$eForceSwitch = $eNull
			$DonateSwitchCounter = 0
		EndIf

	ElseIf $AccType = $eActive Then
		$SwitchCase = $eActive
		MinRemainTrainAcc(False, $nCurProfile)
		$eForceSwitch = $eNull
	Else
		Return False
	EndIf

	If $aProfileType[$nCurProfile - 1] = $eActive And $g_bRequestTroopsEnable = True And $g_bCanRequestCC = True Then
		Setlog("Try Request troops before switching account", $COLOR_BLUE)
		RequestCC(True)
	EndIf

	UpdateTrainTimeStatus("Before")
	SwitchProfile($SwitchCase)
	UpdateTrainTimeStatus()
	If IsMainPage() = False Then checkMainScreen()
	SwitchCOCAcc()
	runBot()
EndFunc   ;==>ForceSwitchAcc

Func SwitchCOCAcc()
	Local $ProfileName = _GUICtrlComboBox_GetListArray($g_hCmbProfile)
	Local $NextAccount, $YCoord, $idx, $idx2, $idx3
	$NextAccount = $aMatchProfileAcc[$nCurProfile - 1]

	If $aAccPosY[$NextAccount - 1] > 0 Then
		$YCoord = $aAccPosY[$NextAccount - 1]
	Else
		$YCoord = 373.5 - ($nTotalCoCAcc - 1) * 36.5 + 73 * ($NextAccount - 1)
	EndIf

	Setlog("Switching to Account [" & $NextAccount & "]")
	If $ichkSwitchAccShared_pref Then
		Setlog("Using SamMod, Shared_Prefs")
		Setlog("Next Account: " & $ProfileName[$nCurProfile] & " acc: " & $NextAccount)
		loadVillageFrom($ProfileName[$nCurProfile])
		If checkProfileCorrect() = True Then
			SetLog("Profile match with village.png, profile loaded correctly.", $COLOR_INFO)
		EndIf
		$bReMatchAcc = False
		$g_abNotNeedAllTime[0] = 1
		$g_abNotNeedAllTime[1] = 1
		$aAttackedCountSwitch[$nCurProfile - 1] = $aAttackedCountAcc[$nCurProfile - 1]
	Else
		PureClick(820, 585, 1, 0, "Click Setting") ;Click setting
		If _Sleep(500) Then Return

		$idx = 0
		While $idx <= 15 ; Checking Green Connect Button continuously in 15sec
			If _ColorCheck(_GetPixelColor(408, 408, True), "D0E878", 20) Then ;	Green
				PureClick(440, 420, 2, 1000) ;	Click Connect & Disconnect
				If _Sleep(500) Then Return
				Setlog("   1. Click connect & disconnect")
				ExitLoop
			ElseIf _ColorCheck(_GetPixelColor(408, 408, True), "F07077", 20) Then ; 	Red
				PureClick(440, 420) ;	Click Disconnect
				If _Sleep(500) Then Return
				Setlog("   1. Click disconnect")
				ExitLoop
			Else
				If _Sleep(900) Then Return
				$idx += 1
				If $idx = 15 Then SwitchFail_runBot()
			EndIf
		WEnd

		$idx = 0
		While $idx <= 15 ; Checking Account List continuously in 15sec
			If _ColorCheck(_GetPixelColor(600, 310, True), "FFFFFF", 20) Then ;	Grey
				PureClick(383, $YCoord) ;	Click Account
				Setlog("   2. Click account [" & $NextAccount & "]")
				If _Sleep(1000) Then Return
				ExitLoop
			ElseIf _ColorCheck(_GetPixelColor(408, 408, True), "F07077", 20) And $idx = 6 Then ; 	Red, double click did not work, try click Disconnect 1 more time
				PureClick(440, 420) ;	Click Disconnect
				Setlog("   1.5. Click disconnect again")
				If _Sleep(500) Then Return
			Else
				If _Sleep(900) Then Return
				$idx += 1
				If $idx = 15 Then SwitchFail_runBot()
			EndIf
		WEnd

		$idx = 0
		While $idx <= 15 ; Checking Load Button continuously in 15sec
			If _ColorCheck(_GetPixelColor(408, 408, True), "D0E878", 20) Then ; Already in current account
				Setlog("Already in current account")
				PureClickP($aAway, 2, 0, "#0167") ;Click Away
				If _Sleep(1000) Then Return
				$bReMatchAcc = False
				ExitLoop

			ElseIf _ColorCheck(_GetPixelColor(480, 441, True), "60B010", 20) Then ; Load Button
				PureClick(443, 430, 1, 0, "Click Load") ;Click Load
				Setlog("   3. Click load button")

				$idx2 = 0
				While $idx2 <= 15 ; Checking Text Box continuously in 15sec
					If _ColorCheck(_GetPixelColor(585, 16, True), "F88088", 20) Then ; Pink (close icon)
						PureClick(360, 195, 1, 0, "Click Text box")
						Setlog("   4. Click text box")
						If _Sleep(500) Then Return
						AndroidSendText("CONFIRM")
						ExitLoop
					Else
						If _Sleep(900) Then Return
						$idx2 = $idx2 + 1
						If $idx2 = 15 Then SwitchFail_runBot()
					EndIf
				WEnd

				$idx3 = 0
				While $idx3 <= 10 ; Checking OKAY Button continuously in 10sec
					If _ColorCheck(_GetPixelColor(480, 200, True), "71BB1E", 20) Then
						PureClick(480, 200, 1, 0, "Click OKAY") ;Click OKAY
						Setlog("   5. Click OKAY")
						ExitLoop
					Else
						If _Sleep(900) Then Return
						$idx3 = $idx3 + 1
						If $idx2 = 10 Then SwitchFail_runBot()
					EndIf
				WEnd

				Setlog("please wait for loading CoC")
				$bReMatchAcc = False
				$g_abNotNeedAllTime[0] = 1
				$g_abNotNeedAllTime[1] = 1
				$aAttackedCountSwitch[$nCurProfile - 1] = $aAttackedCountAcc[$nCurProfile - 1]

				If IsMainPage(100) Then ExitLoop; Waiting for fully load CoC in 10 sec
				ExitLoop

			Else
				If _Sleep(900) Then Return
				$idx += 1
				If $idx = 15 Then SwitchFail_runBot()

			EndIf
		WEnd
	EndIf

EndFunc   ;==>SwitchCOCAcc

Func SwitchFail_runBot()
	Setlog("Switching account failed!", $COLOR_RED)
	$bReMatchAcc = True
	PureClickP($aAway, 3, 500)
	checkMainScreen()
	runBot()
EndFunc   ;==>SwitchFail_runBot

Func DisableGUI_AfterLoadNewProfile()
	$g_bGUIControlDisabled = True
	For $i = $g_hFirstControlToHide To $g_hLastControlToHide
		If IsAlwaysEnabledControl($i) Then ContinueLoop
		If $g_bNotifyPBEnable And $i = $g_hBtnNotifyDeleteMessages Then ContinueLoop ; exclude the DeleteAllMesages button when PushBullet is enabled
		If BitAND(GUICtrlGetState($i), $GUI_ENABLE) Then GUICtrlSetState($i, $GUI_DISABLE)
	Next
	ControlEnable("","",$g_hCmbGUILanguage)
	$g_bGUIControlDisabled = False
EndFunc   ;==>DisableGUI_AfterLoadNewProfile

Func btnMakeSwitchADBFolder()
	Local $currentRunState = $g_bRunState
	Local $bFileFlag = 0
	Local $iCount = 0
	Local $bshared_prefs_file = False
	Local $bVillagePng = False
	Local $sMyProfilePath4shared_prefs = @ScriptDir & "\profiles\" & $g_sProfileCurrentName & "\shared_prefs"

	$g_bRunState = True

	_GUICtrlTab_ClickTab($g_hTabMain, 0)
	SetLog(_PadStringCenter(" Start ", 50, "="),$COLOR_INFO)
	If _Sleep(200) Then Return False
	checkMainScreen(False, False)
	If _Sleep(200) Then Return False

	; remove old village before new copy
	If FileExists(@ScriptDir & "\profiles\" & $g_sProfileCurrentName & "\village_92.png") Then
		SetLog("Removing previous village_92.png", $COLOR_INFO)
		FileDelete(@ScriptDir & "\profiles\" & $g_sProfileCurrentName & "\village_92.png")
		If FileExists(@ScriptDir & "\profiles\" & $g_sProfileCurrentName & "\village_92.png") Then
			SetLog("Cannot remove previous village_92.png", $COLOR_INFO)
		Else
			SetLog("Previous village_92.png removed.", $COLOR_INFO)
		EndIf
	EndIf
	If FileExists($sMyProfilePath4shared_prefs) Then
		SetLog("Removing previous shared_prefs", $COLOR_INFO)
		DirRemove($sMyProfilePath4shared_prefs, 1)
		If FileExists($sMyProfilePath4shared_prefs) Then
			SetLog("Cannot remove previous shared_prefs", $COLOR_INFO)
		Else
			SetLog("Previous shared_prefs removed.", $COLOR_INFO)
		EndIf
	EndIf

	;;;;If Not _CheckColorPixel($aButtonClose3[4], $aButtonClose3[5], $aButtonClose3[6], $aButtonClose3[7], $g_bCapturePixel, "aButtonClose3") Then
		ClickP($aAway, 1, 0, "#0221") ;Click Away
		If _Sleep($DELAYPROFILEREPORT1) Then Return
		If _CheckColorPixel($aIsMain[0], $aIsMain[1], $aIsMain[2], $aIsMain[3], $g_bCapturePixel, "aIsMain") Then
			Click(30, 40, 1, 0, "#0222") ; Click Info Profile Button
			; Waiting for profile page fully load.
			ForceCaptureRegion()
			$iCount = 0
			While 1
				_CaptureRegion()
				If _ColorCheck(_GetPixelColor(250, 95, $g_bNoCapturePixel), Hex(0XE8E8E0,6), 10) = True And _ColorCheck(_GetPixelColor(360, 145, $g_bNoCapturePixel), Hex(0XE8E8E0,6), 10) = False Then
					ExitLoop
				EndIf
				If _Sleep(250) Then Return False
				$iCount += 1
				If $iCount > 40 Then ExitLoop
			WEnd
		Else
			SetLog("Unable to locate main screen.", $COLOR_ERROR)
			Return
		EndIf
	;;;;EndIf

	_CaptureRegion()
	;If _CheckColorPixel($aButtonClose3[4], $aButtonClose3[5], $aButtonClose3[6], $aButtonClose3[7], $g_bNoCapturePixel, "aButtonClose3") Then
		Local $iSecondBaseTabHeight
		If _CheckColorPixel(146,146,0XB8B8A8,10,$g_bNoCapturePixel,"Profile Check Builder Base Tab") = True Then
			$iSecondBaseTabHeight = 49
		Else
			$iSecondBaseTabHeight = 0
		EndIf

		Local $hClone = _GDIPlus_BitmapCloneArea($g_hBitmap, 70,127 + $iSecondBaseTabHeight, 80,17, $GDIP_PXF24RGB)
		_GDIPlus_ImageSaveToFile($hClone, @ScriptDir & "\profiles\" & $g_sProfileCurrentName & "\village_92.png")
		If FileExists(@ScriptDir & "\profiles\" & $g_sProfileCurrentName & "\village_92.png") Then
			SetLog("village_92.png captured.", $COLOR_INFO)
			$bFileFlag = BitOR($bFileFlag, 2)
		EndIf

		;If $g_sAndroidGameDistributor = $g_sGoogle Then
		;	ClickP($aAway,1,0)
		;	If _Sleep(250) Then Return False
		;	Click($aButtonSetting[0],$aButtonSetting[1],1,0,"#Setting")
		;	If Not _Wait4Pixel($aButtonClose2[4], $aButtonClose2[5], $aButtonClose2[6], $aButtonClose2[7], 1500, 100) Then
		;		SetLog("Cannot load setting page, restart game...", $COLOR_RED)
		;	EndIf
		;	If _CheckColorPixel($aButtonGoogleConnectGreen[4], $aButtonGoogleConnectGreen[5], $aButtonGoogleConnectGreen[6], $aButtonGoogleConnectGreen[7], $g_bCapturePixel, "aButtonGoogleConnectGreen") Then
		;		Click($aButtonGoogleConnectGreen[0],$aButtonGoogleConnectGreen[1],1,0,"#ConnectGoogle")
		;	EndIf
		;	If Not _Wait4Pixel($aButtonGoogleConnectRed[4], $aButtonGoogleConnectRed[5], $aButtonGoogleConnectRed[6], $aButtonGoogleConnectRed[7], 1500, 100) Then
		;		SetLog("Cannot disconnect to google.", $COLOR_RED)
		;	Else
		;		SetLog("Disconnected to google.", $COLOR_INFO)
		;	EndIf
		;	ClickP($aAway,1,0)
		;	If Not _Wait4Pixel($aIsMain[0], $aIsMain[1], $aIsMain[2], $aIsMain[3], 1500, 100) Then
		;		SetLog("Cannot back to main screen.", $COLOR_RED)
		;	EndIf
		;EndIf

		Local $lResult

		PoliteCloseCoC()
		;If _Sleep(1500) Then Return False

		;If $g_iSamM0dDebug = 1 Then SetLog("$g_sEmulatorInfo4MySwitch: " & $g_sEmulatorInfo4MySwitch)

		$lResult = RunWait($g_sAndroidAdbPath & " -s " & $g_sAndroidAdbDevice & " shell "& Chr(34) & "su -c 'chmod 777 /data/data/" & $g_sAndroidGamePackage & "/shared_prefs; mkdir /sdcard/tempshared; cp /data/data/" & $g_sAndroidGamePackage & _
		"/shared_prefs/* /sdcard/tempshared; exit; exit'" & Chr(34), "", @SW_HIDE)
		If $lResult = 0 Then
			$lResult = RunWait($g_sAndroidAdbPath & " -s " & $g_sAndroidAdbDevice & " pull /sdcard/tempshared " & Chr(34) & $sMyProfilePath4shared_prefs & Chr(34), "", @SW_HIDE)
			If $lResult = 0 Then
				$lResult = RunWait($g_sAndroidAdbPath & " -s " & $g_sAndroidAdbDevice & " shell "& Chr(34) & "su -c 'rm -r /sdcard/tempshared; exit; exit'" & Chr(34), "", @SW_HIDE)
			EndIf
		EndIf

		If @error Then
			SetLog("Failed to run adb command.", $COLOR_ERROR)
		Else
			If $lResult = 0 Then
				If FileExists($sMyProfilePath4shared_prefs & "\storage.xml") Then
					SetLog("shared_prefs captured.", $COLOR_INFO)
					$bFileFlag = BitOR($bFileFlag, 1)
				EndIf
			Else
				SetLog("Failed to run operate adb command.", $COLOR_ERROR)
			EndIf
		EndIf

		Switch $bFileFlag
			Case 3
				SetLog(GetTranslatedFileIni("sam m0d", "MySwitch_Capture_Msg1", "Sucess: shared_prefs copied and village_92.png captured."), $COLOR_INFO)
			Case 2
				SetLog(GetTranslatedFileIni("sam m0d", "MySwitch_Capture_Msg2", "Failed to copy shared_prefs from emulator, but village_92.png captured."), $COLOR_ERROR)
			Case 1
				SetLog(GetTranslatedFileIni("sam m0d", "MySwitch_Capture_Msg3", "Failed to capture village_92.png from emulator, but shared_prefs copied."), $COLOR_ERROR)
			Case Else
				SetLog(GetTranslatedFileIni("sam m0d", "MySwitch_Capture_Msg4", "Failed to copy shared_prefs and capture village_92.png from emulator."), $COLOR_ERROR)
		EndSwitch
		OpenCoC()
		Wait4Main()
	;Else
	;	SetLog(GetTranslatedFileIni("sam m0d", "MySwitch_Capture_Shared_Prefs_Error", "Please open emulator and coc, then go to profile page before doing this action."), $COLOR_ERROR)
	;EndIf

	SetLog(_PadStringCenter(" End ", 50, "="),$COLOR_INFO)
	$g_bRunState = $currentRunState
EndFunc

Func btnPushshared_prefs()
	Local $currentRunState = $g_bRunState
	$g_bRunState = True

	SetLog("Start")
	PoliteCloseCoC()
	;If _Sleep(1500) Then Return False
	Local $lResult
	Local $sMyProfilePath4shared_prefs = @ScriptDir & "\profiles\" & $g_sProfileCurrentName & "\shared_prefs"
	Local $hostPath = $g_sAndroidPicturesHostPath & $g_sAndroidPicturesHostFolder & "shared_prefs"
	Local $androidPath = $g_sAndroidPicturesPath & StringReplace($g_sAndroidPicturesHostFolder, "\", "/") & "shared_prefs/"

	If FileExists($sMyProfilePath4shared_prefs & "\storage.xml") Then
		$lResult = DirCopy($sMyProfilePath4shared_prefs, $hostPath, 1)
		If $lResult = 1 Then
			$lResult = RunWait($g_sAndroidAdbPath & " -s " & $g_sAndroidAdbDevice & " shell "& Chr(34) & "su -c 'chmod 777 /data/data/" & $g_sAndroidGamePackage & "/shared_prefs; " & _
			"cp -r " & $androidPath & "* /data/data/" & $g_sAndroidGamePackage & "/shared_prefs; cd /data/data/" & $g_sAndroidGamePackage & "/shared_prefs; " & _
			"find -name 'com.facebook.internal.preferences.APP_SETTINGS.xml' -type f -exec rm -f {} +; " & _
			"find -name 'com.google.android.gcm.xml' -type f -exec rm -f {} +; " & _
			"find -name 'com.mobileapptracking.xml' -type f -exec rm -f {} +; " & _
			"find -name '*.bak' -type f -exec rm -f {} +; " & _
			"exit; exit'" & Chr(34), "", @SW_HIDE)

			;"find -name 'HSJsonData.xml' -type f -exec rm -f {} +; " & _
			;"find -name 'mat_queue.xml' -type f -exec rm -f {} +; " & _
			;"find -name 'openudid_prefs.xml' -type f -exec rm -f {} +; " & _
			;"find -name 'localPrefs.xml' -type f -exec rm -f {} +; " & _

			DirRemove($hostPath, 1)
		EndIf
		If $lResult = 0 Then
			SetLog("shared_prefs copy to emulator should be okay.", $COLOR_INFO)
			OpenCoC()
			Wait4Main()
		EndIf
	Else
		SetLog($sMyProfilePath4shared_prefs & "\storage.xml not found.", $COLOR_ERROR)
	EndIf
	SetLog("Finish")
	$g_bRunState = $currentRunState
EndFunc

Func Wait4Main($bBuilderBase = False)
	Local $iCount
	For $i = 0 To 105
		$iCount += 1
		If $iCount > 120 Then ExitLoop
		Setlog("Wait4Main Loop = " & $i & "   ExitLoop = " & $iCount, $COLOR_DEBUG) ; Debug stuck loop
		ClickP($aAway, 1, 0, "#0221") ;Click Away
		ForceCaptureRegion()
		_CaptureRegion()
		If _CheckColorPixel($aIsMain[0], $aIsMain[1], $aIsMain[2], $aIsMain[3], $g_bNoCapturePixel, "aIsMain") Then
			Setlog("Main Village - Screen cleared, Wait4Main exit", $COLOR_DEBUG)
			Return True
		ElseIf _CheckColorPixel($aIsOnBuilderIsland[0], $aIsOnBuilderIsland[1], $aIsOnBuilderIsland[2], $aIsOnBuilderIsland[3], $g_bNoCapturePixel, "aIsOnBuilderIsland") Then
			If Not $bBuilderBase Then
				ZoomOut()
				SwitchBetweenBases()
				If $i <> 0 Then $i -= 1
				ContinueLoop
			EndIf
			Setlog("Builder Base - Screen cleared, Wait4Main exit", $COLOR_DEBUG)
			Return True
		Else
			If TestCapture() = False And _Sleep($DELAYWAITMAINSCREEN1) Then Return
			; village was attacked okay button
			If _ColorCheck(_GetPixelColor(402, 516, $g_bNoCapturePixel), Hex(0xFFFFFF, 6), 5) And _ColorCheck(_GetPixelColor(405, 537, $g_bNoCapturePixel), Hex(0x5EAC10, 6), 20) Then
				;Click($aButtonVillageWasAttackOK[0],$aButtonVillageWasAttackOK[1],1,0,"#VWAO")
				$g_abNotNeedAllTime[0] = True
				$g_abNotNeedAllTime[1] = True
				$g_bIsClientSyncError = False
				If _Sleep(500) Then Return True
				$i = 0
				ContinueLoop
			EndIf
			_CaptureRegion2Sync()
			If _checkObstacles() Then $i = 0
		EndIf
	Next
	Return False
EndFunc

Func _CheckColorPixel($x, $y, $sColor, $iColorVariation, $bFCapture = True, $sMsglog = Default)
	Local $hPixelColor = _GetPixelColor2($x, $y, $bFCapture)
	Local $bFound = _ColorCheck($hPixelColor, Hex($sColor,6), Int($iColorVariation))
	Local $COLORMSG = ($bFound = True ? $COLOR_BLUE : $COLOR_RED)
	If $sMsglog <> Default And IsString($sMsglog) Then
		Local $String = $sMsglog & " - Ori Color: " & Hex($sColor,6) & " at X,Y: " & $x & "," & $y & " Found: " & $hPixelColor
		SetLog($String, $COLORMSG)
	EndIf
	Return $bFound
EndFunc

Func _GetPixelColor2($iX, $iY, $bNeedCapture = False)
	Local $aPixelColor = 0
	If $bNeedCapture = False Or $g_bRunState = False Then
		$aPixelColor = _GDIPlus_BitmapGetPixel($g_hBitmap, $iX, $iY)
	Else
		_CaptureRegion($iX - 1, $iY - 1, $iX + 1, $iY + 1)
		$aPixelColor = _GDIPlus_BitmapGetPixel($g_hBitmap, 1, 1)
	EndIf
	Return Hex($aPixelColor, 6)
EndFunc   ;==>_GetPixelColors

Func loadVillageFrom($Profilename)
	PoliteCloseCoC()
	;If _Sleep(1500) Then Return False
	Local $lResult
	Local $sMyProfilePath4shared_prefs = @ScriptDir & "\profiles\" & $Profilename & "\shared_prefs"
	Local $hostPath = $g_sAndroidPicturesHostPath & $g_sAndroidPicturesHostFolder & "shared_prefs"
	Local $androidPath = $g_sAndroidPicturesPath & StringReplace($g_sAndroidPicturesHostFolder, "\", "/") & "shared_prefs/"

	$lResult = DirCopy($sMyProfilePath4shared_prefs, $hostPath, 1)
	If $lResult = 1 Then
		$lResult = RunWait($g_sAndroidAdbPath & " -s " & $g_sAndroidAdbDevice & " shell "& Chr(34) & "su -c 'chmod 777 /data/data/" & $g_sAndroidGamePackage & "/shared_prefs; " & _
		"cp -r " & $androidPath & "* /data/data/" & $g_sAndroidGamePackage & "/shared_prefs; cd /data/data/" & $g_sAndroidGamePackage & "/shared_prefs; " & _
		"find -name 'com.facebook.internal.preferences.APP_SETTINGS.xml' -type f -exec rm -f {} +; " & _
		"find -name 'com.google.android.gcm.xml' -type f -exec rm -f {} +; " & _
		"find -name 'com.mobileapptracking.xml' -type f -exec rm -f {} +; " & _
		"find -name '*.bak' -type f -exec rm -f {} +; " & _
		"exit; exit'" & Chr(34), "", @SW_HIDE)

		;"find -name 'HSJsonData.xml' -type f -exec rm -f {} +; " & _
		;"find -name 'mat_queue.xml' -type f -exec rm -f {} +; " & _
		;"find -name 'openudid_prefs.xml' -type f -exec rm -f {} +; " & _
		;"find -name 'localPrefs.xml' -type f -exec rm -f {} +; " & _

		DirRemove($hostPath, 1)
	EndIf

	If $lResult = 0 Then
		SetLog("shared_prefs copy to emulator should be okay.", $COLOR_INFO)
		;If $iMySwitchSmartWaitTime > 0 Then
		;	SmartWait4TrainMini($iMySwitchSmartWaitTime, 1)
		;	$iMySwitchSmartWaitTime = 0
		;Else
			OpenCoC()
			Wait4Main()
		;EndIf
		Return True
	EndIf

	Return False
EndFunc

Func checkProfileCorrect()
	If IsMainPage() Then
		ClickP($aAway, 1, 0, "#0221") ;Click Away
		;Click($aButtonOpenProfile[0],$aButtonOpenProfile[1],1,0,"#0222")
		Click(30, 40, 1, 0, "#0222") ; Click Info Profile Button
		If _Sleep(1000) Then Return False

		Local $iCount, $iImageNotMatchCount
		Local $bVillagePageFlag = False
		Local $iSecondBaseTabHeight

		; Waiting for profile page fully load.
		ForceCaptureRegion()
		$iCount = 0
		While 1
			_CaptureRegion()
			If _ColorCheck(_GetPixelColor(250, 95, $g_bNoCapturePixel), Hex(0XE8E8E0,6), 10) = True And _ColorCheck(_GetPixelColor(360, 145, $g_bNoCapturePixel), Hex(0XE8E8E0,6), 10) = False Then
				ExitLoop
			EndIf
			If _Sleep(250) Then Return False
			$iCount += 1
			If $iCount > 40 Then ExitLoop
		WEnd

		$iCount = 0
		$iImageNotMatchCount = 0

		While 1
			_CaptureRegion()
			If _ColorCheck(_GetPixelColor(146, 146, $g_bNoCapturePixel), Hex(0XB8B8A8,6), 10) = True Then
				$iSecondBaseTabHeight = 49
			Else
				$iSecondBaseTabHeight = 0
			EndIf

			If $g_iSamM0dDebug = 1 Then SetLog("_GetPixelColor(85, " & 163 + $iSecondBaseTabHeight & ", True): " & _GetPixelColor(85, 163 + $iSecondBaseTabHeight, $g_bNoCapturePixel))
			If $g_iSamM0dDebug = 1 Then SetLog("_GetPixelColor(20, " & 295 + $iSecondBaseTabHeight & ", True): " & _GetPixelColor(20, 295 + $iSecondBaseTabHeight, $g_bNoCapturePixel))

			$bVillagePageFlag = _ColorCheck(_GetPixelColor(85, 163 + $iSecondBaseTabHeight, $g_bNoCapturePixel), Hex(0X959AB6,6), 20) = True And _ColorCheck(_GetPixelColor(20, 295 + $iSecondBaseTabHeight, $g_bNoCapturePixel), Hex(0X4E4D79,6), 10) = True

			If $bVillagePageFlag = True Then
				_CaptureRegion(68,125 + $iSecondBaseTabHeight,155,146 + $iSecondBaseTabHeight)
				Local $result = DllCall($g_hLibImgLoc, "str", "FindTile", "handle", $g_hHBitmap, "str", @ScriptDir & "\profiles\" & $g_sProfileCurrentName & "\village_92.png", "str", "FV", "int", 1)
				If @error Then _logErrorDLLCall($g_sLibImgLocPath, @error)
				If IsArray($result) Then
					If $g_iSamM0dDebug = 1 Then SetLog("DLL Call succeeded " & $result[0], $COLOR_ERROR)
					If $result[0] = "0" Or $result[0] = "" Then
						If $g_iSamM0dDebug = 1 Then SetLog("Image not found", $COLOR_ERROR)
						$bVillagePageFlag = False
						$iImageNotMatchCount += 1
						If $iImageNotMatchCount > 3 Then
							Return False
						EndIf
					ElseIf StringLeft($result[0], 2) = "-1" Then
						SetLog("DLL Error: " & $result[0], $COLOR_ERROR)
					Else
						If $g_iSamM0dDebug = 1 Then SetLog("$result[0]: " & $result[0])
						Local $aCoor = StringSplit($result[0],"|",$STR_NOCOUNT)
						If IsArray($aCoor) Then
							If StringLeft($aCoor[1], 2) <> "-1" Then
								ExitLoop
							EndIf
						EndIf
					EndIf
				EndIf
			Else
				ClickDrag(380, 140 + $g_iMidOffsetY + $iSecondBaseTabHeight, 380, 580 + $g_iMidOffsetY, 500)
			EndIf
			$iCount += 1
			If $iCount > 15 Then
				SetLog("Cannot load profile page...", $COLOR_RED)
				ClickP($aAway,1,0)
				Return False
			EndIf
			If _Sleep(100) Then Return False
		WEnd

		ClickP($aAway,1,0)
		If _Sleep(1000) Then Return True
		Return True
	EndIf
	Return False
EndFunc