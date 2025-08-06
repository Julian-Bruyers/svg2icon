@echo off
REM svg2icon Uninstallation Script for Windows
REM Removes svg2icon binary and cleans up PATH entries
REM Usage: uninstall.bat

setlocal enabledelayedexpansion

set "BINARY_NAME=svg2icon.exe"
set "REMOVED_COUNT=0"

echo svg2icon Uninstallation Script
echo ==============================

REM Check common installation directories
set "INSTALL_PATHS="
set "FOUND_PATHS="

REM Check Program Files
if exist "%ProgramFiles%\svg2icon\%BINARY_NAME%" (
    set "FOUND_PATHS=!FOUND_PATHS!%ProgramFiles%\svg2icon\%BINARY_NAME%;"
)

REM Check Local AppData
if exist "%LOCALAPPDATA%\svg2icon\%BINARY_NAME%" (
    set "FOUND_PATHS=!FOUND_PATHS!%LOCALAPPDATA%\svg2icon\%BINARY_NAME%;"
)

REM Check if it's in PATH
where %BINARY_NAME% >nul 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=*" %%i in ('where %BINARY_NAME% 2^>nul') do (
        set "PATH_LOCATION=%%i"
        echo !FOUND_PATHS! | findstr /C:"!PATH_LOCATION!" >nul
        if !errorlevel! neq 0 (
            set "FOUND_PATHS=!FOUND_PATHS!!PATH_LOCATION!;"
        )
    )
)

REM Check if any installations found
if "!FOUND_PATHS!"=="" (
    echo svg2icon is not installed or not found in common locations
    pause
    exit /b 0
)

REM Display found installations
echo.
echo Found svg2icon installations:
for %%i in (!FOUND_PATHS!) do (
    if not "%%i"=="" (
        echo   - %%i
    )
)
echo.

REM Confirm uninstallation
echo This will remove svg2icon from your system.
set /p "CONFIRM=Do you want to continue? (y/N): "
if /i not "!CONFIRM!"=="y" (
    echo Uninstallation cancelled
    pause
    exit /b 0
)

echo.

REM Remove binaries
for %%i in (!FOUND_PATHS!) do (
    if not "%%i"=="" (
        call :remove_binary "%%i"
    )
)

REM Clean up PATH entries - DISABLED
REM PATH entries are preserved to avoid breaking user configuration
call :clean_path_entries

REM Final verification
where %BINARY_NAME% >nul 2>&1
if !errorlevel! equ 0 (
    echo WARNING: svg2icon is still found in PATH (but PATH entries were preserved)
    echo The binary has been removed, but PATH entries remain in your environment
) else (
    echo SUCCESS: svg2icon binary successfully removed
)

echo.
if !REMOVED_COUNT! gtr 0 (
    echo svg2icon uninstallation completed!
    echo Removed !REMOVED_COUNT! installation(s)
) else (
    echo No installations were removed
)

pause
exit /b 0

:remove_binary
set "BINARY_PATH=%~1"
set "INSTALL_DIR=%~dp1"

echo Removing binary: !BINARY_PATH!

REM Try to remove the file
del "!BINARY_PATH!" >nul 2>&1
if !errorlevel! equ 0 (
    echo SUCCESS: Successfully removed: !BINARY_PATH!
    set /a REMOVED_COUNT+=1
    
    REM Remove empty directory if it's one we created
    call :cleanup_directory "!INSTALL_DIR!"
) else (
    echo ERROR: Failed to remove: !BINARY_PATH!
    echo This might be because the file is in use or you lack permissions.
)
goto :eof

:cleanup_directory
set "DIR_PATH=%~1"

echo Preserving installation directory: !DIR_PATH!
echo Directory will not be removed even if empty
goto :eof

:clean_path_entries
echo Preserving PATH entries...
echo PATH entries will remain in your environment to avoid breaking configuration

REM Get current user PATH for information only
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "USER_PATH=%%b"

if defined USER_PATH (
    echo.
    echo Current PATH entries that contain 'svg2icon':
    for %%p in ("!USER_PATH:;=" "!") do (
        set "CURRENT_PATH=%%~p"
        echo !CURRENT_PATH! | findstr /C:"svg2icon" >nul
        if !errorlevel! equ 0 (
            echo   - !CURRENT_PATH!
        )
    )
    echo.
    echo These PATH entries have been preserved and will remain active
)
goto :eof
