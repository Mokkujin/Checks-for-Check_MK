'###################################################################################################
'#                                                                                                 #
'#   Autor        : Christopher Pope                                                               #
'#   Version      : 0.0.1                                                                          #
'#   Beschreibung : Check_MK Local Check für Windows 2008 Quotas                                   #
'#                                                                                                 #
'###################################################################################################
Option Explicit
'On Error Resume Next
Dim ObjWsh : Set ObjWsh = CreateObject("WScript.Shell")
Dim ObjFso : Set ObjFso = CreateObject("Scripting.FileSystemObject")
Dim ScPath : ScPath = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))
Dim VaDate : VaDate = Date()
Dim LgPath : LgPath = ScPath & Replace(WScript.ScriptName,".vbs","") & "\"
Dim LgFile : LgFile = "QUOTA_CHECK.txt"
Dim LgComp : LgComp = LgPath & LgFile
Dim shQuota : shQuota = "dirquota quota list"
Dim StrMes : StrMes = ""
'------------
Dim FPfad,QVorlage,KStatus,Verwendet,KPfad,CHKSTATUS,CHKTEXT,TXT_DUMMY,CNT
'-------
Dim VarInterval : VarInterval = 4 ' Hour
CNT = 0

Check_Temp_Folder(LgPath)

If Check_Run(LgComp) Then
	GetQuotas(LgComp)
End If

If ObjFso.FileExists(LgComp) Then
Dim RFile : Set RFile = ObjFso.OpenTextFile(LgComp)
Dim RLine
Do Until RFile.AtEndOfStream
	RLine = Trim(LCase(RFile.ReadLine))
	If Left(RLine,Len("Kontingentpfad:")) = LCASE("Kontingentpfad:") Then
		KPfad = Trim(Mid(RLine,Len("Kontingentpfad:") + 1))
		KPfad = Trim(Mid(KPfad,InStrRev(KPfad,"\")+1))
	End If
	If Left(RLine,Len("Freigabepfad:")) = LCASE("Freigabepfad:") Then
		FPfad = Mid(RLine,Len("Freigabepfad:"))
		FPfad = Replace(FPfad,":","")
		FPfad = Trim(FPfad)
	End If
	If Left(RLine,Len("Quellenvorlage:")) = LCASE("Quellenvorlage:") Then
		QVorlage = Mid(RLine,Len("Quellenvorlage:"))
		QVorlage = Replace(QVorlage,":","")
		QVorlage = Trim(QVorlage)
	End If
	If Left(RLine,Len("Kontingentstatus:")) = LCASE("Kontingentstatus:") Then
		KStatus = Mid(RLine,Len("Kontingentstatus:"))
		KStatus = Replace(KStatus,":","")
		KStatus = Trim(KStatus)
	End If
	If Left(RLine,Len("Verwendet:")) = LCASE("Verwendet:") Then
		Verwendet = Mid(RLine,InStr(RLine,"(")+1 ,Len(RLine) - InStr(RLine,"(") - 2)
		
	End If
	
	If FPfad <> "" And QVorlage <> ""  And KStatus <> "" And Verwendet <> "" Then
		CHKTEXT = "Freigabe : " & FPfad & " - Status : " & KStatus & " - Auslastung : " & Verwendet & " Prozent" & " - Last Check : " & GetLogTime(LgComp)
		Verwendet = CInt(Verwendet)
		If Verwendet <= 90 Then
			CHKSTATUS = "0" ' ok !
		End If
		If Verwendet => 91 And Verwendet <= 95 Then
			CHKSTATUS = "1" ' warning 
		End If
		If Verwendet => 96 And Verwendet <= 100 Then
			CHKSTATUS = "2" ' critical
		End If
		
		If TXT_DUMMY = "" Then
			TXT_DUMMY = CHKSTATUS & vbTab _
			          & "QUOTA-" & KPfad & vbTab _
			          & "-" & vbTab _
			          & CHKTEXT
		Else
			TXT_DUMMY = TXT_DUMMY & vbCrLf _
					  & CHKSTATUS & vbTab _
					  & "QUOTA-" & KPfad & vbTab _
					  & "-" & vbTab _
					  & CHKTEXT
		End If
		
		FPfad = ""
		QVorlage = ""
		KStatus = ""
		Verwendet = ""
		
		CNT = CNT + 1
		
	End If
Loop

	WScript.Echo TXT_DUMMY

End If





' --------------------------------------------------------------------------------------------------
Function GetDate()
	Dim Dummy
	Dummy = Year(Date())
	If Month(Now) > 10 Then
		Dummy = Dummy & Month(Now)
	Else
		Dummy = Dummy & "0" & Month(Now)
	End If
	If Day(Now) > 10 Then
		Dummy = Dummy & Day(Now)
	Else
		Dummy = Dummy & "0" & Day(Now)
	End If
	GetDate = Dummy
End Function
' --------------------------------------------------------------------------------------------------
Function GetLogTime(File)
	Dim DumLGTime
	If ObjFso.FileExists(File) Then
		DumLGTime = ObjFso.GetFile(File).DateLastModified
	Else
		DumLGTime = "could not check"
	End If
	GetLogTime = DumLGTime
End Function
' --------------------------------------------------------------------------------------------------
Function GetQuotas(Path)
	If ObjFso.FileExists(Path) Then
		ObjFso.DeleteFile Path,True
	End If
	ObjWsh.Run "%comspec% /C " & shQuota & " > " & Chr(34) & Path & Chr(34),0,True
	GetQuotas = True
End Function
' --------------------------------------------------------------------------------------------------
Function Check_Run(File)
	Dim FuncLR
	If ObjFso.FileExists(File) = True Then
		FuncLR = ObjFso.GetFile(File).DateLastModified
		If DateDiff("h",FuncLR,Now) < VarInterval Then
			Check_Run = False
		Else
			Check_Run = True
		End If
	Else
		Check_Run = True
	End If
	Set FuncLR = Nothing
End Function
' --------------------------------------------------------------------------------------------------
Function Check_Temp_Folder(Path)
	If ObjFso.FolderExists(Path) = False Then
		ObjFso.CreateFolder Path
	End If
End Function