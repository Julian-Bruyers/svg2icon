@echo off
REM Build script for svg2icon - Windows Batch
REM Compiles svg2icon for Windows, macOS, and Linux on AMD64 and ARM architectures

setlocal enabledelayedexpansion

REM Validate environment
where go >nul 2>&1
if !errorlevel! neq 0 (
    echo Error: Go is not installed or not in PATH >&2
    exit /b 1
)

REM Check if we're in the correct directory
if not exist "go.mod" (
    echo Error: Must be run from the project root directory (where go.mod exists) >&2
    exit /b 1
)
if not exist "main.go" (
    echo Error: main.go not found in current directory >&2
    exit /b 1
)

echo Building svg2icon for multiple platforms...

REM Create build directory safely
if not exist "build" (
    mkdir build
    if !errorlevel! neq 0 (
        echo Error: Failed to create build directory >&2
        exit /b 1
    )
)

REM Clean previous builds safely
del /Q build\svg2icon_* 2>nul

REM Function to build target
call :build_target "windows" "amd64" ".exe" "Windows AMD64"
if !errorlevel! neq 0 exit /b 1

call :build_target "windows" "arm64" ".exe" "Windows ARM64"
if !errorlevel! neq 0 exit /b 1

echo.
call :build_target "darwin" "amd64" "" "macOS AMD64"
if !errorlevel! neq 0 exit /b 1

call :build_target "darwin" "arm64" "" "macOS ARM64"
if !errorlevel! neq 0 exit /b 1

echo.
call :build_target "linux" "amd64" "" "Linux AMD64"
if !errorlevel! neq 0 exit /b 1

call :build_target "linux" "arm64" "" "Linux ARM64"
if !errorlevel! neq 0 exit /b 1

echo.
echo Build completed successfully!
echo Binaries available in build\ directory:

REM List binaries safely
dir /B build\svg2icon_* 2>nul
if !errorlevel! neq 0 (
    echo No binaries found
    exit /b 1
)

REM Display file sizes
echo.
echo Binary sizes:
for %%f in (build\svg2icon_*) do (
    for /f "tokens=3" %%s in ('dir /a-d "%%f" ^| findstr /C:"%%~nxf"') do (
        echo %%~nxf: %%s bytes
    )
)

REM Clean up environment variables
set GOOS=
set GOARCH=
goto :eof

:build_target
set "GOOS_VAL=%~1"
set "GOARCH_VAL=%~2"
set "EXT=%~3"
set "DESC=%~4"

echo Building for !DESC!...

set "BINARY_NAME=svg2icon_!GOOS_VAL!_!GOARCH_VAL!!EXT!"
set "OUTPUT_PATH=build\!BINARY_NAME!"

set GOOS=!GOOS_VAL!
set GOARCH=!GOARCH_VAL!

go build -ldflags="-s -w" -o "!OUTPUT_PATH!" .
if !errorlevel! neq 0 (
    echo Error: Failed to build !DESC! >&2
    exit /b 1
)

REM Verify binary was created and is not empty
if not exist "!OUTPUT_PATH!" (
    echo Error: Binary !BINARY_NAME! was not created >&2
    exit /b 1
)

for %%F in ("!OUTPUT_PATH!") do (
    if %%~zF==0 (
        echo Error: Binary !BINARY_NAME! is empty >&2
        exit /b 1
    )
)

echo ✓ !DESC! built successfully
exit /b 0