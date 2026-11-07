@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Val-Patcher

rem ==========================================================================
rem  Val-Patcher: puts your own video in as the VALORANT menu background while
rem  the game runs, then restores the original when the game closes, so normal
rem  launches never trigger a Riot repair. It only copies a video file; nothing
rem  is injected into the game.
rem
rem    launcher.bat            launch (or attach to) VALORANT with your video
rem    launcher.bat --restore  put the original video back now
rem    launcher.bat --check    show the detected paths and files, change nothing
rem    launcher.bat --setup    first-time setup (same as setup.bat)
rem
rem  Full desktop app with a UI, tray and auto-detection: Veil Launcher
rem  https://github.com/ChirisaCasey/veil-launcher
rem ==========================================================================

set "ROOT=%~dp0"
set "CUSTOM=%ROOT%Custom"
set "BACKUPS=%ROOT%Backups"
set "FLAG=%ROOT%Backups\swapped.txt"
set "GAME_EXE=VALORANT-Win64-Shipping.exe"
rem Seconds to wait after the game process appears, so Riot's file check is done.
set "SWAP_DELAY=5"

call :find_paths || goto :fail

if /i "%~1"=="--check"   goto :check
if /i "%~1"=="--restore" goto :restore_cmd
if /i "%~1"=="--setup"   goto :setup
if not "%~1"=="" (
    echo Unknown option "%~1". Use --check, --restore or --setup.
    goto :fail
)

rem ---------------------------------------------------------------- main ----
if not exist "%CUSTOM%" mkdir "%CUSTOM%" 2>nul
if not exist "%BACKUPS%" mkdir "%BACKUPS%" 2>nul

rem A swap left over from a session that didn't finish (window closed, crash):
rem resume it if the game is still running, otherwise put the original back first.
if exist "%FLAG%" (
    call :game_running
    if !errorlevel!==0 (
        set /p TARGET=<"%FLAG%"
        call :find_custom >nul
        echo Resuming: VALORANT is already running with your video.
        goto :wait_exit
    )
    echo Restoring the original video from a previous session...
    call :restore || goto :fail
)

call :find_custom || goto :fail
call :find_target || goto :fail

rem The game folder now holds the genuine file: refresh the backup every run,
rem so a VALORANT patch (new file name or content) never leaves a stale backup.
del /q "%BACKUPS%\*.mp4" 2>nul
copy /y "%MENU%\%TARGET%" "%BACKUPS%\%TARGET%" >nul || (
    echo Could not back up "%TARGET%".
    goto :fail
)

call :game_running
if %errorlevel%==0 (
    echo VALORANT is already running. Patching the current session.
) else (
    call :launch || goto :fail
    echo Waiting for VALORANT to start...
    call :wait_start || goto :fail
    echo VALORANT started. Waiting %SWAP_DELAY%s for Riot's file check...
    timeout /t %SWAP_DELAY% /nobreak >nul
)

copy /y "%CUSTOM_FILE%" "%MENU%\%TARGET%" >nul
if errorlevel 1 (
    echo.
    echo Could not write to the VALORANT folder.
    echo If VALORANT is installed somewhere protected, right-click launcher.bat
    echo and choose "Run as administrator".
    goto :fail
)
>"%FLAG%" echo %TARGET%

:wait_exit
cls
echo  Val-Patcher
echo  ----------------------------------------------------------
echo  Your video is in: %CUSTOM_NAME%
echo  Replacing:        %TARGET%
echo.
echo  Play as usual. When VALORANT closes, the original video is
echo  restored automatically. Keep this window open (you can minimize it).
echo.
echo  Tip: don't click inside this window; selecting text pauses the script.
:wait_exit_loop
timeout /t 3 /nobreak >nul
call :game_running
if %errorlevel%==0 goto :wait_exit_loop

echo.
echo VALORANT closed. Restoring the original video...
call :restore || goto :fail
echo Done. The original menu video is back.
timeout /t 4 >nul
exit /b 0

rem -------------------------------------------------------------- modes ----
:check
echo VALORANT folder: %LIVE%
echo Menu folder:     %MENU%
echo Riot Client:     %RC%
call :find_target && echo Menu video:      !TARGET!
call :find_custom && echo Your video:      !CUSTOM_FILE!
if exist "%FLAG%" (echo Swap active:     yes) else (echo Swap active:     no)
pause
exit /b 0

:restore_cmd
call :game_running
if %errorlevel%==0 (
    echo VALORANT is running. Close it first, then run --restore again.
    goto :fail
)
if not exist "%FLAG%" (
    echo Nothing to restore: the original video is already in place.
    timeout /t 4 >nul
    exit /b 0
)
call :restore || goto :fail
echo Done. The original menu video is back.
timeout /t 4 >nul
exit /b 0

:setup
if not exist "%CUSTOM%" mkdir "%CUSTOM%"
if not exist "%BACKUPS%" mkdir "%BACKUPS%"
call :find_target || goto :fail
if not exist "%FLAG%" (
    del /q "%BACKUPS%\*.mp4" 2>nul
    copy /y "%MENU%\%TARGET%" "%BACKUPS%\%TARGET%" >nul && echo Backed up %TARGET%.
)
echo.
echo Setup done.
echo   VALORANT found at: %LIVE%
echo   Now put an .mp4 in the "Custom" folder and run launcher.bat.
start "" explorer "%CUSTOM%"
pause
exit /b 0

rem ------------------------------------------------------------ helpers ----
:find_paths
rem VALORANT "live" folder: path.txt (optional override) -> Riot's own metadata.
set "LIVE="
set "PT="
if exist "%ROOT%path.txt" set /p PT=<"%ROOT%path.txt"
if defined PT (
    set "PT=!PT:"=!"
    if exist "!PT!\live\ShooterGame" set "LIVE=!PT!\live"
    if not defined LIVE if exist "!PT!\ShooterGame" set "LIVE=!PT!"
)
if not defined LIVE call :live_from_metadata
if not defined LIVE (
    echo Could not find VALORANT.
    echo Put your VALORANT folder ^(e.g. C:\Riot Games\VALORANT^) in path.txt.
    exit /b 1
)
set "LIVE=!LIVE:/=\!"
if "!LIVE:~-1!"=="\" set "LIVE=!LIVE:~0,-1!"
set "MENU=!LIVE!\ShooterGame\Content\Movies\Menu"
if not exist "!MENU!" (
    echo Menu folder not found: !MENU!
    exit /b 1
)
call :riot_client
exit /b 0

:live_from_metadata
set "META=%ProgramData%\Riot Games\Metadata\valorant.live\valorant.live.product_settings.yaml"
if not exist "%META%" exit /b 0
for /f tokens^=2^ delims^=^" %%A in ('findstr /c:"product_install_full_path" "%META%"') do set "LIVE=%%A"
exit /b 0

:riot_client
rem RiotClientServices.exe: Riot's install list -> next to the VALORANT folder.
set "RC="
set "RCI=%ProgramData%\Riot Games\RiotClientInstalls.json"
if exist "%RCI%" (
    for /f tokens^=1-4^ delims^=^" %%A in ('findstr /c:"rc_live" /c:"rc_default" "%RCI%"') do (
        if not defined RC (
            if "%%B"=="rc_live" set "RC=%%D"
            if "%%B"=="rc_default" set "RC=%%D"
            if "%%A"=="rc_live" set "RC=%%C"
            if "%%A"=="rc_default" set "RC=%%C"
        )
    )
)
if defined RC set "RC=!RC:/=\!"
if defined RC if not exist "!RC!" set "RC="
if not defined RC if exist "!LIVE!\..\..\Riot Client\RiotClientServices.exe" set "RC=!LIVE!\..\..\Riot Client\RiotClientServices.exe"
exit /b 0

:find_target
rem The menu loop is the newest *Homescreen*.mp4 (e.g. 13_06_Homescreen.mp4). Sorted by date,
rem not name, because "9_..." would sort after "13_...".
set "TARGET="
for /f "delims=" %%F in ('dir /b /a-d /o-d "%MENU%\*Homescreen*.mp4" 2^>nul') do if not defined TARGET set "TARGET=%%F"
if not defined TARGET (
    echo No *Homescreen*.mp4 found in "%MENU%".
    exit /b 1
)
exit /b 0

:find_custom
set "CUSTOM_FILE="
set "CUSTOM_NAME="
for /f "delims=" %%F in ('dir /b /a-d /o-n "%CUSTOM%\*.mp4" 2^>nul') do if not defined CUSTOM_FILE (
    set "CUSTOM_FILE=%CUSTOM%\%%F"
    set "CUSTOM_NAME=%%F"
)
if not defined CUSTOM_FILE (
    echo No .mp4 in the "Custom" folder. Put the video you want there first.
    exit /b 1
)
exit /b 0

:game_running
tasklist /fi "imagename eq %GAME_EXE%" /nh 2>nul | find /i "%GAME_EXE%" >nul
exit /b %errorlevel%

:launch
if defined RC (
    start "" "%RC%" --launch-product=valorant --launch-patchline=live
    exit /b 0
)
if exist "%ROOT%VALORANT.lnk" (
    start "" "%ROOT%VALORANT.lnk"
    exit /b 0
)
echo Could not find the Riot Client to launch VALORANT.
echo Start VALORANT yourself now; Val-Patcher will pick it up.
exit /b 0

:wait_start
rem Up to 10 minutes (Riot updates can take a while).
for /l %%i in (1,1,300) do (
    call :game_running
    if !errorlevel!==0 exit /b 0
    timeout /t 2 /nobreak >nul
)
echo VALORANT didn't start within 10 minutes. Nothing was changed.
exit /b 1

:restore
if not exist "%FLAG%" exit /b 0
set /p RTARGET=<"%FLAG%"
if not exist "%BACKUPS%\%RTARGET%" (
    echo Backup of "%RTARGET%" is missing. Use "Repair" in the Riot Client to get it back.
    exit /b 1
)
copy /y "%BACKUPS%\%RTARGET%" "%MENU%\%RTARGET%" >nul || (
    echo Could not restore "%RTARGET%". Try running as administrator.
    exit /b 1
)
del /q "%FLAG%"
exit /b 0

:fail
echo.
pause
exit /b 1
