@echo off
setlocal
powershell.exe -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0installer\Manage-Mod.ps1" -Mode Install
if errorlevel 1 echo Installation stopped. See the message above; no administrator elevation is automatic.
pause
