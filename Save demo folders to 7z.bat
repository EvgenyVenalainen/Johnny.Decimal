set fn=demo-folders.7z
if exist %fn% move %fn% %fn%.bak
for /d %%d in (*) do  ("C:\Program Files\7-Zip\7z.exe" a %fn% "%%d")