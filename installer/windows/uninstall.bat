@echo off
setlocal
powershell.exe -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0installer\Manage-Mod.ps1" -Mode Uninstall
if errorlevel 1 echo Uninstallation stopped. See the message above.
pause
