del .\Export\html5\bin\*.js
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -command "[int32](New-TimeSpan -Start (Get-Date "01/01/1970") -End (Get-Date)).TotalSeconds"`) DO (
SET buildtime=%%F
)
powershell -Command "(gc project.xml) -replace 'file=\"\d*?\"', 'file=\"%buildtime%\"' | Out-File -encoding ASCII project.xml"
lime build html5 -D prod