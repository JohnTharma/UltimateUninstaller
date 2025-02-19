REM This is the Installation script

:: It launches on 64bit CMD and continues installation of 64bit software

IF NOT "%PROCESSOR_ARCHITEW6432%"=="AMD64" GOTO native
ECHO "Re-launching Script in Native Command Processor..."

EXIT

:native
@echo off
cd /d %~dp0
pushd %~dp0
setlocal ENABLEDELAYEDEXPANSION

Rem set the application name (adjust as per your actual application name)
set AppName=Sample App
set AppVersion=1.0.0.1

Rem Create folder to store logs if it doesn't exist
set AppLog=C:\Temp\Logs\%AppName%
if not exist "%AppLog%" mkdir "%AppLog%"

REM Close any conflicting applications
taskkill /F /IM sampleapp.exd

REM Install application silently(exe)
start /wait "sampleapp.exe" /allusers /verysilent /norestart -i /S

REM Install application silently(MSI)
start /wait msiexec.exe /i "sampleapp.msi" /qn ALLUSERS=1 /l*v "%logfile%" /norestart

REM Install apps(portable)
REM Copy files to installation directory
mkdir "C:\samplefolder\sampleapp" 2>nul
xcopy /Y /I ".\sampleapp\*" "C:\samplefolder\sampleapp" /E /H /C

REM Add entry to registry
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%AppName% /V DisplayName /t REG_SZ /d "%AppName%" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%AppName% /V DisplayVersion /t REG_SZ /d "%AppVersion%" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%AppName% /V UninstallString /t REG_SZ /d "reg delete \"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%AppName%\" /f" /f

REM Clear previous Uninstallation log
del /s /q "C:\Temp\Logs\%AppName% - Uninstall.log"

Rem Log Installation completion
echo Installed "%AppName%" >> "%AppLog%\%AppName% - Install.log"

timeout /t 30

exit /b

REM This is the Uninstallation script

:: It launches on 64bit CMD and continues installation of 64bit software

IF NOT "%PROCESSOR_ARCHITEW6432%"=="AMD64" GOTO native
ECHO "Re-launching Script in Native Command Processor..."

EXIT

:native
@echo off
cd /d %~dp0
pushd %~dp0
setlocal ENABLEDELAYEDEXPANSION

Rem set the application name (adjust as per your actual application name)
set AppName=Sample App

REM Remove Installation directory and shortcuts
rmdir /s /q "C:\SampleFolder\Sampleapp" 2>nul
DEL "C:\Users\Public\Desktop\sampleapp.ink" /q

REM Run Uninstaller(For .exe)
"C:\SampleFolder\Sampleapp\unins000.exe" /allusers /verysilent /norestart -i /S

REM Uninstall application silently(MSI)
start /wait msiexec.exe /x {msi string} /qn ALLUSERS=1 /l*v "%logfile%" /norestart

REM Clear Installation log
rmdir /s /q "C:\Temp\Logs\%AppName%" 2>nul

Rem Log Uninstallation completion
echo Uninstalled "%AppName%" >> "%AppLog%\%AppName% - Uninstall.log"

REM Cleanup Registry
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%AppName%\" /f

timeout /t 30

exit /b







