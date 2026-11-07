@echo off
rem First-time setup: finds VALORANT, creates the Custom and Backups folders and
rem backs up the original menu video. All the logic lives in launcher.bat.
call "%~dp0launcher.bat" --setup
