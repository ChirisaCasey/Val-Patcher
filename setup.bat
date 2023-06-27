@ECHO OFF
set /p vpath=<"%~dp0path.txt"
set vpath="%vpath%\live\ShooterGame\Content\Movies\Menu\"
xcopy /s /y %vpath%Home*.mp4 "%~dp0Backups\" >NUL

