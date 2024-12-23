@ECHO OFF
set /p vpath=<"%~dp0path.txt"
set vpath="%vpath%\live\ShooterGame\Content\Movies\Menu\"
xcopy /s /y %vpath%*Homescreen.mp4 "%~dp0Backups\" >NUL
mkdir "%~dp0Custom"
