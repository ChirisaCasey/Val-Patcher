@ECHO OFF
set /p vpath=<"%~dp0path.txt"
set /A isrun=0

echo Loading, Do not click window.

call :init

:loop
call :detect
if %isrun%==1 (goto :main) else (goto :loop)
EXIT /B 0

:main
FOR %%X in ("%~dp0Backups\*.mp4") DO (xcopy "%~dp0Custom\*.mp4" %vpath%%%~nX.mp4 /y >NUL)
cls
echo Press enter to exit valorant.
pause >NUL
TASKKILL /f /IM VALORANT-Win64-Shipping.exe >NUL
xcopy "%~dp0Backups\*.mp4" %vpath% /s /y >NUL
EXIT

:init
set vpath="%vpath%\live\ShooterGame\Content\Movies\Menu\"
call :detect
if %isrun%==0 (call :runproc && goto :loop) else (goto :main)
EXIT /B 0

:detect
tasklist /fi "ImageName eq VALORANT-Win64-Shipping.exe" /fo csv 2>NUL | find /I "VALORANT-Win64-Shipping.exe" >NUL 
if "%ERRORLEVEL%"=="0" (set isrun=1) else (set isrun=0)
EXIT /B 0

:runproc
start "" "%~dp0VALORANT.lnk"
EXIT /B 0
