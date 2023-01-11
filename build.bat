FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -command "[int32](New-TimeSpan -Start (Get-Date "01/01/1970") -End (Get-Date)).TotalSeconds"`) DO (SET buildtime=%%F)

del .\build\html5\*.js

powershell -Command "(gc ./build/html5/index.html) -replace '<script src=\"\d*?\.js\"', '<script src=\"%buildtime%.js\"' | Out-File -encoding ASCII ./build/html5/index.html"
powershell -Command "(gc ./html5.hxml) -replace '-js build/html5/\d*?\.js', '-js build/html5/%buildtime%.js' | Out-File -encoding ASCII ./html5.hxml"

haxe html5.hxml