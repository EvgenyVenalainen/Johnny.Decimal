;;; Нормализация имён папок
;;; 2024-05-13 - первая рабочая версия
;;; 2024-07-20 - последняя правка

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
n_area = 0 ; количество арий
n_cate = 0 ; количество категорий

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
		n_area++
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
				n_cate++
			}

;;; Сообщение о результатах
IfEqual, total, 1, MsgBox, 64, Итого , Нормализовано папок: `t %count% `n Пропущено папок: `t %skip%

;;; Файл index.md
FileDelete, %index%
FileEncoding, UTF-8
RegExMatch(root, "[^\\]*$", x)
bytes := GetFolderSize(root, c, false)
FileAppend, # %x% [%c%](<file:///%root%>) A%n_area%/C%n_cate%`n, %index%
chart = `n`n---`n`n# Chart of categories`n``````tinychart`n
Loop Files, %root%\*.*, D
	if A_LoopFileName ~= "^\d"
	{
		bytes := GetFolderSize(A_LoopFileFullPath, c, false)
		FileAppend, ---`n## %A_LoopFileName% [%c%](<file:///%A_LoopFileFullPath%>)`n, %index%
		Loop Files, %A_LoopFileFullPath%\*.*, D
			if A_LoopFileName ~= "^\d\d\s"
			{
				bytes := GetFolderSize(A_LoopFileFullPath, c, false)
				FileAppend, ### %A_LoopFileName% [%c%](<file:///%A_LoopFileFullPath%>)`n, %index%
				chart .= A_LoopFileName . Format(", {:d}", bytes) . "`n"
				indexID := A_LoopFileFullPath . "\" . SubStr(A_LoopFileName, 1, 2) . ".00"
				IfExist, %indexID%
				{
					If FileExist(indexID . "\*.jpg") or FileExist(indexID . "\*.jpeg") or FileExist(indexID . "\*.png")
					{
						t := A_Language=00419 ? "Вид" : "Look"
						FileAppend, > [!tip]- %t%`n, %index%
						Loop Files, %indexID%\*.*, F
							If InStr("jpg_jpeg_png", A_LoopFileExt)
								FileAppend, ![](<%A_LoopFileFullPath%>)&nbsp;, %index%
						FileAppend, `n`n, %index%
					}
					IfExist, %indexID%\index.md
					{
						t := A_Language=00419 ? "Суть" : "Point"
						FileAppend, > [!info]- %t%`n, %index%
						Loop, read, %indexID%\index.md
							FileAppend, >%A_LoopReadLine%`n, %index%
						FileAppend, `n, %index%
					}
				}
				If FileExist(A_LoopFileFullPath . "\" . SubStr(A_LoopFileName, 1, 2) . "*")
				{
					t := A_Language=00419 ? "Склад" : "Store"
					FileAppend, > [!example]- %t%`n, %index%
					Loop Files, %A_LoopFileFullPath%\*.*, D
						if A_LoopFileName ~= "^\d\d\.\d\d"
						{
							bytes := GetFolderSize(A_LoopFileFullPath, c)
							c := A_LoopFileName . " [" . c . "](<file:///" . A_LoopFileFullPath . ">)`n"
							FileAppend, %c%, %index%
						}
					FileAppend, `n, %index%
				}
			}
	} else if Not A_LoopFileName ~= "^\." {
		bytes := GetFolderSize(A_LoopFileFullPath, c)
		chart .= A_LoopFileName . Format(", {:d}", bytes) . "`n"
	}

chart .= "```````n"
FileAppend, %chart%, %index%
IfExist, %index%.jpg
	FileAppend, ---`n![[index.md.jpg]]`n, %index%
ExitApp

;;; Размер файлов в папке в МБ
GetFolderSize(path, ByRef s, isFloat:=true)
{
;LCID_0019 := "Russian"  ; ru
;LCID_0819 := "Russian (Moldova)"  ; ru-MD
;LCID_0419 := "Russian (Russia)"  ; ru-RU
	size := ComObjCreate("Scripting.FileSystemObject").GetFolder(path).Size / 1024 / 1024
	x := "(" . (isFloat ? "{:.1f}" : "{:d}") . "&nbsp;" . (A_Language=00419 ? "МБ" : "MB") . ")"
	s := Format(x, size)
	if isFloat and (A_Language=00419)	; запятая дробной части по-русски
		s := StrReplace(s, ".", ",")
	if (size > 999)		; отбивка тысяч апострофом
	{
		i := StrLen( Format("{:d}", size/1000) )
		s := SubStr(s, 1, i+1) . "'" .  SubStr(s, i+2)
	}
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
RenameDir(s, n, b:=0) ; b=1 - сохраняем двубуквие
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

