::It launches on 64bit CMD,Extracts software software GUID, and Then use the GUID to search the name and version
@ECHO OFF

IF NOT "%PROCESSOR_ARCHITEW6432%"=="AMD64" GOTO native
ECHO "Re-launching Script in Native Command Processor..." 
%SystemRoot%\Sysnative\cmd.exe /c %0 %*
EXIT

:native
@echo off
pushd %~dp0
setlocal ENABLEDELAYEDEXPANSION

set SoftwareName=HeidiSQL
set VersionToBeRemoved=12.0
set LogDir=C:\Temp\Logs
set LogFile=%LogDir%\%SoftwareName% - MassUninstall Version %VersionToBeRemoved%.log
set x86GUID=HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall
set x64GUID=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
set x86HKCU=HKCU\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall
set x64HKCU=HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
set UninstallParameters=/QN /norestart /S /Q -q

REM Create the log directory if it doesn't exist
if not exist "%LogDir%" mkdir "%LogDir%"

REM It's faster to first locate the software GUID, then search its Name, Version & UninstallString
for %%G in ("%x86GUID%" "%x64GUID%") do (
    for /f "delims=" %%P in ('reg query "%%~G" /s /f "%SoftwareName%" 2^>nul ^| findstr "HKEY_LOCAL_MACHINE"') do (
        echo %%P
        for /f "tokens=2*" %%A in ('reg query "%%P" /v "DisplayVersion" 2^>nul ^| findstr "DisplayVersion"') do (
            set InstalledVersion=%%B
            if "!InstalledVersion!" LEQ "%VersionToBeRemoved%" (
                echo Found older version !InstalledVersion!, initiating uninstall...
                for /f "tokens=2*" %%C in ('reg query "%%P" /v "UninstallString" 2^>nul ^| findstr "UninstallString"') do (
                    echo %%D | findstr /c:"MsiExec.exe" >nul && (
                        set MsiStr=%%D
                        set MsiStr=!MsiStr:/I=/X!
                        echo !MsiStr! %UninstallParameters%
                        !MsiStr! %UninstallParameters%
                        call :logMessage Uninstalling older version !InstalledVersion! using !MsiStr! %UninstallParameters%
                    ) || (
                        echo None MsiExec Uninstall String %%D
                        %%D %UninstallParameters%
                        call :logMessage Uninstalling older version !InstalledVersion! using %%D %UninstallParameters%
                    )
                )
            ) else (
                echo Found newer version !InstalledVersion!, skipping...
                call :logMessage Skipping uninstall for newer version !InstalledVersion!
                timeout /t 5
            )
        )
    )
)

REM Function to log messages with date and time
:logMessage
echo [%date% %time%] %* (Script Executed) >> "%LogFile%"
exit /b

:end
endlocal
popd
timeout /t 3
