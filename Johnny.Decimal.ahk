;;; Нормализация имён папок
;;; 2024-05-13 - первая рабочая версия

root := A_WorkingDir
index := root
vault = Obsidian Vault
IfExist, %vault%
	index .= "\" . vault
index .= "\index.md"

if Not A_IsCompiled {
;	root := A_WorkingDir
;	index := A_WorkingDir . "\index.md"
}

total = 0 ; 1 - сообщить итоги работы
mode = 0 ; 1 - сообщать о папках с несистемным именем
count = 0 ; счётчик нормализованных папок
skip = 0 ; счётчки пропущенных папок

;;; Первый проход, первый заход в Areas
Loop Files, %root%\*.*, D
{
;	if RenameDir( "^\d\d\s", 4, 1) ; 12 текст -> 12 Текст
;		continue
	if RenameDir( "^\d\d-\d\d", 6) ; 12-34текст -> 10-19 Текст
		continue
	if RenameDir( "^\d\d", 3) ; 12текст -> 10-19 Текст
		continue
	if RenameDir( "^\d", 2) ; 1текст -> 10-19 Текст
		continue
}

;;; Второй проход, первый заход в Categories
Loop Files, %root%\*.*, D
	if A_LoopFileName ~= "^\d"
	{
		i := SubStr(A_LoopFileName, 1, 1)
		Loop Files, %A_LoopFileFullPath%\*.*, D
		{
			if A_LoopFileName ~= "^\d\d" ; X*\YZтекст -> X*\XZтекст
			{
				c := A_LoopFileDir . "\" . i . SubStr(A_LoopFileName, 2)
				FileMoveDir, %A_LoopFileFullPath%, %c%, R
				count++
				continue
			}
			if A_LoopFileName ~= "^\d" ; X*\Zтекст -> X*\XZтекст
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

;;; Третий проход, второй заход в Categories
Loop Files, %root%\*.*, D
	if A_LoopFileName ~= "^\d"
		Loop Files, %A_LoopFileFullPath%\*.*, D
			RenameDir( "^\d\d", 3, 1) ; X*\XZтекст -> X*\XZ Текст

;;; Четвёртый проход, первый заход в Items
loop Files, %root%\*.*, D
	if A_LoopFileName ~= "^\d"
		Loop Files, %A_LoopFileFullPath%\*.*, D
			if A_LoopFileName ~= "^\d\d\s"
			{
				i := SubStr(A_LoopFileName, 1, 2)
				с := false
				Loop Files, %A_LoopFileFullPath%\*.*, D
				{
					if A_LoopFileName ~= "^\d\d\.\d\d" ; XY\AB.CDтекст -> XY\XY.CD Текст
						c := A_LoopFileDir . "\" . i . "." . SubStr(A_LoopFileName, 4, 2) . " " . Sentence(SubStr(A_LoopFileName, 6))
					else if A_LoopFileName ~= "^\d\d\.\d" ; XY\Cтекст -> XY\XY.0C Текст
						c := A_LoopFileDir . "\" . i . ".0" . SubStr(A_LoopFileName, 4, 1) . " " . Sentence(SubStr(A_LoopFileName, 5))
					else if A_LoopFileName ~= "^\d\d" ; XY\CDтекст -> XY\XY.CD Текст
						c := A_LoopFileDir . "\" . i . "." . SubStr(A_LoopFileName, 1, 2) . " " . Sentence(SubStr(A_LoopFileName, 3))
					else if A_LoopFileName ~= "^\d" ; XY\Cтекст -> XY\XY.0C Текст
						c := A_LoopFileDir . "\" . i . ".0" . SubStr(A_LoopFileName, 1, 1) . " " . Sentence(SubStr(A_LoopFileName, 2))
					If c
					{
						FileMoveDir, %A_LoopFileFullPath%, %c%, R
						count++
					}
					else
						FolderAlert(3)
				}
			}

;;; Сообщение о результатах
IfEqual, total, 1, MsgBox, 64, Итого , Нормализовано папок: `t %count% `n Пропущено папок: `t %skip%

;;; Файл index.md
FileDelete, %index%
FileEncoding, UTF-8
RegExMatch(root, "[^\\]*$", x)
bytes := GetFolderSize(root, c)
FileAppend, # %x% [%c%](<file:///%root%>), %index%
chart = `n`n---`n`n# Chart of categories`n``````tinychart
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
					if A_LoopFileName ~= "^\d\d\.\d\d\s"
					{
						bytes := GetFolderSize(A_LoopFileFullPath, c)
						c := "`n" . A_LoopFileName . " [" . c . "](<file:///" . A_LoopFileFullPath . ">)"
						FileAppend, %c%, %index%
					}
			}
	} else if Not A_LoopFileName ~= "^\." {
		bytes := GetFolderSize(A_LoopFileFullPath, c)
		chart .= "`n" . A_LoopFileName . Format(", {:d}", bytes)
	}

chart .= "`n``````"
;msgbox % chart
FileAppend, %chart%, %index%

ExitApp

;;; Размер файлов в папке в МБ
GetFolderSize(path, ByRef s)
{
;LCID_0019 := "Russian"  ; ru
;LCID_0819 := "Russian (Moldova)"  ; ru-MD
;LCID_0419 := "Russian (Russia)"  ; ru-RU
	size := ComObjCreate("Scripting.FileSystemObject").GetFolder(path).Size / 1024 / 1024
	x := "({:.1f}&nbsp;" . (A_Language=00419 ? "МБ" : "MB") . ")"
	s := Format(x, size)
	return size
}

;;; Сообщение о неформатной папке и ея уровне
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

;;; Делает первую букву строки прописной
Sentence(s)
{
	z := Trim(s)
	x := SubStr(z, 1, 1)
	StringUpper, x, x
	y := SubStr(z, 2)
;	StringLower, y, y
	return x . y
}

;;; Меняет имя Area (b=0) или Category (b=1)
RenameDir(s, n, b=0) ; b=1 - сохраняем двубуквие
{
	global
	res := RegExMatch(A_LoopFileName, s, x)
	if res
	{
		a := SubStr(A_LoopFileName, 1, 1+b) ; только первая цифра или две первых
		c := Sentence(SubStr(A_LoopFileName, n)) ; текст
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

