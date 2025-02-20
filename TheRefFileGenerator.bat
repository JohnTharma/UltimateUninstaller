@echo off
setlocal enabledelayedexpansion
chcp 65001

rem Specify the name of the software you want to retrieve information for
set "SOFTWARE_NAME=trellix"

rem Specify the location of the ref.txt file
set "OUTPUT_FILE=ref.txt"

rem Initialize variables to store information
set "SOFTWARE_FOUND="

rem Query the 32-bit registry for the specified software
for /f "tokens=*" %%a in ('reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "%SOFTWARE_NAME%" /reg:32 2^>nul') do (
    set "KEY=%%a"
    for /f "tokens=1,*" %%b in ('reg query "!KEY!" /v DisplayName 2^>nul') do (
        if "%%b"=="DisplayName" (
            set "DISPLAY_NAME=%%c"
            set "SOFTWARE_PATH=!KEY!"
            set "ARCH=32-bit"
            set "SOFTWARE_FOUND=1"
        )
    )

    rem If software is found, retrieve additional information
    if defined SOFTWARE_FOUND (
        for /f "tokens=1,*" %%b in ('reg query "!SOFTWARE_PATH!" /v DisplayVersion 2^>nul') do (
            if "%%b"=="DisplayVersion" set "DISPLAY_VERSION=%%c"
        )
        for /f "tokens=1,*" %%b in ('reg query "!SOFTWARE_PATH!" /v ModifyPath 2^>nul') do (
            if "%%b"=="ModifyPath" set "MODIFY_PATH=%%c"
        )
        for /f "tokens=1,*" %%b in ('reg query "!SOFTWARE_PATH!" /v InstallLocation 2^>nul') do (
            if "%%b"=="InstallLocation" set "INSTALL_PATH=%%c"
        )
        for /f "tokens=1,*" %%b in ('reg query "!SOFTWARE_PATH!" /v Publisher 2^>nul') do (
            if "%%b"=="Publisher" set "PUBLISHER=%%c"
        )
        for /f "tokens=1,*" %%b in ('reg query "!SOFTWARE_PATH!" /v UninstallString 2^>nul') do (
            if "%%b"=="UninstallString" set "UNINSTALL_STRING=%%c"
        )

        rem Export the gathered information to the output file
        echo Registry Path: >> "%OUTPUT_FILE%"
        echo !SOFTWARE_PATH! >> "%OUTPUT_FILE%"
        echo. >> "%OUTPUT_FILE%"
        echo DisplayName: >> "%OUTPUT_FILE%"
        echo !DISPLAY_NAME! >> "%OUTPUT_FILE%"
        echo. >> "%OUTPUT_FILE%"
        echo DisplayVersion: >> "%OUTPUT_FILE%"
        echo !DISPLAY_VERSION! >> "%OUTPUT_FILE%"
        echo. >> "%OUTPUT_FILE%"
        echo ModifyPath: >> "%OUTPUT_FILE%"
        echo !MODIFY_PATH! >> "%OUTPUT_FILE%"
        echo. >> "%OUTPUT_FILE%"
        echo Install Path: >> "%OUTPUT_FILE%"
        echo !INSTALL_PATH! >> "%OUTPUT_FILE%"
        echo. >> "%OUTPUT_FILE%"
        echo Publisher: >> "%OUTPUT_FILE%"
        echo !PUBLISHER! >> "%OUTPUT_FILE%"
        echo. >> "%OUTPUT_FILE%"
        echo Uninstallation String: >> "%OUTPUT_FILE%"
        echo !UNINSTALL_STRING! >> "%OUTPUT_FILE%"
        echo. >> "%OUTPUT_FILE%"
        
        rem Clear variables for next search
        set "SOFTWARE_FOUND="
    )
)

rem Query the 64-bit registry for the specified software if not found in 32-bit registry
if not defined SOFTWARE_FOUND (
    for /f "tokens=*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "%SOFTWARE_NAME%" /reg:64 2^>nul') do (
        set "KEY=%%a"
        for /f "tokens=1,*" %%b in ('reg query "!KEY!" /v DisplayName 2^>nul') do (
            if "%%b"=="DisplayName" (
                set "DISPLAY_NAME=%%c"
                set "SOFTWARE_PATH=!KEY!"
                set "ARCH=64-bit"
                set "SOFTWARE_FOUND=1"
            )
        )

        rem If software is found, retrieve additional information
        if defined SOFTWARE_FOUND (
            for /f "tokens=1,*" %%b in ('reg query "!SOFTWARE_PATH!" /v DisplayVersion 2^>nul') do (
                if "%%b"=="DisplayVersion" set "DISPLAY_VERSION=%%c"
            )
            for /f "tokens=1,*" %%b in ('reg query "!SOFTWARE_PATH!" /v ModifyPath 2^>nul') do (
                if "%%b"=="ModifyPath" set "MODIFY_PATH=%%c"
            )
            for /f "tokens=1,*" %%b in ('reg query "!SOFTWARE_PATH!" /v InstallLocation 2^>nul') do (
                if "%%b"=="InstallLocation" set "INSTALL_PATH=%%c"
            )
            for /f "tokens=1,*" %%b in ('reg query "!SOFTWARE_PATH!" /v Publisher 2^>nul') do (
                if "%%b"=="Publisher" set "PUBLISHER=%%c"
            )
            for /f "tokens=1,*" %%b in ('reg query "!SOFTWARE_PATH!" /v UninstallString 2^>nul') do (
                if "%%b"=="UninstallString" set "UNINSTALL_STRING=%%c"
            )

            rem Export the gathered information to the output file
            echo Registry Path: >> "%OUTPUT_FILE%"
            echo !SOFTWARE_PATH! >> "%OUTPUT_FILE%"
            echo. >> "%OUTPUT_FILE%"
            echo DisplayName: >> "%OUTPUT_FILE%"
            echo !DISPLAY_NAME! >> "%OUTPUT_FILE%"
            echo. >> "%OUTPUT_FILE%"
            echo DisplayVersion: >> "%OUTPUT_FILE%"
            echo !DISPLAY_VERSION! >> "%OUTPUT_FILE%"
            echo. >> "%OUTPUT_FILE%"
            echo ModifyPath: >> "%OUTPUT_FILE%"
            echo !MODIFY_PATH! >> "%OUTPUT_FILE%"
            echo. >> "%OUTPUT_FILE%"
            echo Install Path: >> "%OUTPUT_FILE%"
            echo !INSTALL_PATH! >> "%OUTPUT_FILE%"
            echo. >> "%OUTPUT_FILE%"
            echo Publisher: >> "%OUTPUT_FILE%"
            echo !PUBLISHER! >> "%OUTPUT_FILE%"
            echo. >> "%OUTPUT_FILE%"
            echo Uninstallation String: >> "%OUTPUT_FILE%"
            echo !UNINSTALL_STRING! >> "%OUTPUT_FILE%"
            echo. >> "%OUTPUT_FILE%"
            
            rem Clear variables for next search
            set "SOFTWARE_FOUND="
        )
    )
)

rem If the software is not found, exit
if not defined SOFTWARE_FOUND (
    echo Software "%SOFTWARE_NAME%" not found.
    exit /b
)

echo Information exported to %OUTPUT_FILE%
