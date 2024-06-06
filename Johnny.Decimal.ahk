;;; Нормализация имён папок
;;; 2024-05-13

if A_IsCompiled
{
	root := A_WorkingDir
	index := root
	vault = Obsidian Vault
	IfExist, %vault%
		index = %index%\%vault%
	index .= "\index.md"
} else {
	root := A_WorkingDir
	index := A_WorkingDir . "\index.md"
}

total = 0
mode = 0
count = 0
skip = 0

Loop Files, %root%\*.*, D
{
	if RenameDir( "^\d\d\s", 4, true)
		continue
	if RenameDir( "^\d\d-\d\d", 6)
		continue
	if RenameDir( "^\d\d", 3)
		continue
	if RenameDir( "^\d", 2)
		continue
}

Loop Files, %root%\*.*, D
	if A_LoopFileName ~= "^\d"
	{
		i := SubStr(A_LoopFileName, 1, 1)
		Loop Files, %A_LoopFileFullPath%\*.*, D
		{
			if A_LoopFileName ~= "^\d\d"
			{
				c := A_LoopFileDir . "\" . i . SubStr(A_LoopFileName, 2)
				FileMoveDir, %A_LoopFileFullPath%, %c%, R
				count++
				continue
			}
			if A_LoopFileName ~= "^\d"
			{
				c := A_LoopFileDir . "\" . i . A_LoopFileName
				FileMoveDir, %A_LoopFileFullPath%, %c%, R
				count++
				continue
			}
			FolderAlert(2)
		}
	} else
		FolderAlert(1)


Loop Files, %root%\*.*, D
	if A_LoopFileName ~= "^\d"
		Loop Files, %A_LoopFileFullPath%\*.*, D
			RenameDir( "^\d\d", 3, true)

Loop Files, %root%\*.*, D
	if A_LoopFileName ~= "^\d"
		Loop Files, %A_LoopFileFullPath%\*.*, D
			if A_LoopFileName ~= "^\d\d\s"
			{
				i := SubStr(A_LoopFileName, 1, 2)
				Loop Files, %A_LoopFileFullPath%\*.*, D
				{
					if A_LoopFileName ~= "^\d\d\.\d\d"
					{
						c := A_LoopFileDir . "\" . i . "." . SubStr(A_LoopFileName, 4, 2) . " " . Sentence(SubStr(A_LoopFileName, 6))
						FileMoveDir, %A_LoopFileFullPath%, %c%, R
						count++
						continue
					}
					if A_LoopFileName ~= "^\d\d\s"
					{
						c := A_LoopFileDir . "\" . i . "." . SubStr(A_LoopFileName, 1, 2) . " " . Sentence(SubStr(A_LoopFileName, 3))
						FileMoveDir, %A_LoopFileFullPath%, %c%, R
						count++
						continue
					}
					FolderAlert(3)
				}
			}


IfEqual, total, 1, MsgBox, 64, Итого , Нормализовано папок: `t %count% `n Пропущено папок: `t %skip%

FileDelete, %index%
FileEncoding, UTF-8
RegExMatch(root, "[^\\]*$", x)
bytes := GetFolderSize(root, c)
FileAppend, # %x% [%c%](<file:///%root%>), %index%
chart = `n---`n# Chart`n``````tinychart
Loop Files, %root%\*.*, D
	if A_LoopFileName ~= "^\d"
	{
		bytes := GetFolderSize(A_LoopFileFullPath, c)
		FileAppend, `n`n---`n## %A_LoopFileName% [%c%](<file:///%A_LoopFileFullPath%>), %index%
		Loop Files, %A_LoopFileFullPath%\*.*, D
			if A_LoopFileName ~= "^\d\d\s"
			{
				bytes := GetFolderSize(A_LoopFileFullPath, c)
				FileAppend, `n### %A_LoopFileName% [%c%](<file:///%A_LoopFileFullPath%>)`n, %index%
				chart .= "`n" . A_LoopFileName . Format(", {:d}", bytes)
				Loop Files, %A_LoopFileFullPath%\*.*, D
					if A_LoopFileName ~= "^\d\d\.\d\d"
					{
						bytes := GetFolderSize(A_LoopFileFullPath, c)
						c := "`n" . A_LoopFileName . " [" . c . "](<file:///" . A_LoopFileFullPath . ">)"
						FileAppend, %c%, %index%
					}
			}
	} else {
		bytes := GetFolderSize(A_LoopFileFullPath, c)
		chart .= "`n" . A_LoopFileName . Format(", {:d}", bytes)
	}

chart .= "`n``````"
;msgbox % chart
FileAppend, %chart%, %index%

ExitApp

GetFolderSize(path, ByRef s)
{
	size := ComObjCreate("Scripting.FileSystemObject").GetFolder(path).Size / 1024 / 1024
	s := Format("({:.1f}&nbsp;МБ)", size)
	return size
}



FolderAlert(l)
{
	global
	skip++
	If mode = 1
		MsgBox, 49, Уровень: %l%, %A_LoopFileDir% `n`n`t %A_LoopFileName%
		IfMsgBox, Cancel
			ExitApp
	return
}


Sentence(s)
{
	z := Trim(s)
	x := SubStr(z, 1, 1)
	StringUpper, x, x
	y := SubStr(z, 2)
;	StringLower, y, y
	return x . y
}


RenameDir(s, n, b=false)
{
	global
	res := RegExMatch(A_LoopFileName, s, x)
	if res
	{
		a := SubStr(A_LoopFileName, 1, 1+b)
		c := Sentence(SubStr(A_LoopFileName, n))
		if b {
			c := A_LoopFileDir . "\" . a . " " . c
		} else {
			c := A_LoopFileDir . "\" . a . "0-" . a . "9 " . c
		}
		FileMoveDir, %A_LoopFileFullPath%, %c%, R
		count++
	}
	return res
}


