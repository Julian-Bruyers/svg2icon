# svg2icon installer script for Windows PowerShell
# Downloads and installs the latest release from GitHub
# Usage: iwr -useb https://raw.githubusercontent.com/julian-bruyers/svg2icon/main/scripts/install.ps1 | iexvg2icon Installation Script for Windows PowerShell
# Downloads and installs the latest release from GitHub
# Usage: iwr -useb https://raw.githubusercontent.com/Julian-Bruyers/svg2icon/main/scripts/install.ps1 | iex

[CmdletBinding()]
param(
    [string]$InstallDir = "",
    [switch]$Force
)

# Configuration
$Repo = "julian-bruyers/svg2icon"
$BinaryName = "svg2icon.exe"
$DefaultInstallDir = "$env:LOCALAPPDATA\svg2icon"

# Helper functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "Error: $Message" "Red"
    exit 1
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput $Message "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput $Message "Yellow"
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput $Message "Cyan"
}

# Detect architecture
function Get-Architecture {
    $arch = $env:PROCESSOR_ARCHITECTURE
    switch ($arch) {
        "AMD64" { return "amd64" }
        "ARM64" { return "arm64" }
        default { Write-Error "Unsupported architecture: $arch" }
    }
}

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Determine installation directory
function Get-InstallDirectory {
    if ($InstallDir) {
        return $InstallDir
    }
    
    # Check if running as administrator
    if (Test-Administrator) {
        $systemDir = "$env:ProgramFiles\svg2icon"
        Write-Info "Running as administrator. Installing to system directory: $systemDir"
        return $systemDir
    } else {
        Write-Info "Installing to user directory: $DefaultInstallDir"
        return $DefaultInstallDir
    }
}

# Get latest release version with improved error handling
function Get-LatestVersion {
    try {
        $apiUrl = "https://api.github.com/repos/$Repo/releases/latest"
        
        # Use Invoke-RestMethod with timeout and error handling
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get -TimeoutSec 30 -ErrorAction Stop
        
        if (-not $response -or -not $response.tag_name) {
            throw "Invalid response from GitHub API"
        }
        
        $version = $response.tag_name
        
        # Validate version format
        if ($version -notmatch '^v?\d+\.\d+\.\d+(-[\w\.-]+)?(\+[\w\.-]+)?$') {
            throw "Invalid version format: $version"
        }
        
        return $version
        
    } catch [System.Net.WebException] {
        Write-Error "Network error accessing GitHub API: $_"
    } catch {
        Write-Error "Failed to get latest version: $_"
    }
}

# Download and install binary with enhanced safety
function Install-Binary {
    param(
        [string]$Version,
        [string]$Architecture,
        [string]$InstallPath
    )
    
    # Validate inputs
    if ([string]::IsNullOrWhiteSpace($Version) -or [string]::IsNullOrWhiteSpace($Architecture) -or [string]::IsNullOrWhiteSpace($InstallPath)) {
        Write-Error "Invalid parameters provided to Install-Binary"
        return
    }
    
    $platform = "windows_$Architecture"
    $binaryName = "svg2icon_$platform.exe"
    $downloadUrl = "https://github.com/$Repo/releases/download/$Version/$binaryName"
    
    Write-Info "Downloading svg2icon $Version for $platform..."
    
    # Create secure temporary directory
    try {
        $tempDir = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_ }
        $tempFile = Join-Path $tempDir $binaryName
    } catch {
        Write-Error "Failed to create temporary directory: $_"
        return
    }
    
    try {
        # Create backup of existing binary
        if (Test-Path $InstallPath) {
            $backupPath = "$InstallPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            try {
                Copy-Item $InstallPath $backupPath -Force
                Write-Info "Backup created: $backupPath"
            } catch {
                Write-Warning "Could not create backup of existing binary"
            }
        }
        
        # Download binary with timeout and error handling
        try {
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "svg2icon-installer/1.0")
            $webClient.DownloadFile($downloadUrl, $tempFile)
        } catch [System.Net.WebException] {
            Write-Error "Network error downloading binary: $_"
            return
        } catch {
            Write-Error "Failed to download binary: $_"
            return
        } finally {
            if ($webClient) { $webClient.Dispose() }
        }
        
        # Verify downloaded file
        if (!(Test-Path $tempFile) -or (Get-Item $tempFile).Length -eq 0) {
            Write-Error "Downloaded file is missing or empty"
            return
        }
        
        # Create installation directory safely
        $installDir = Split-Path $InstallPath -Parent
        if (!(Test-Path $installDir)) {
            try {
                New-Item -ItemType Directory -Path $installDir -Force | Out-Null
                Write-Info "Created installation directory: $installDir"
            } catch {
                Write-Error "Failed to create installation directory: $_"
                return
            }
        }
        
        # Copy binary to installation directory with verification
        try {
            Copy-Item $tempFile $InstallPath -Force
            
            # Verify installation
            if (!(Test-Path $InstallPath) -or (Get-Item $InstallPath).Length -eq 0) {
                Write-Error "Binary installation verification failed"
                return
            }
            
            Write-Success "svg2icon installed to $InstallPath"
        } catch {
            Write-Error "Failed to install binary: $_"
            return
        }
        
    } finally {
        # Always clean up temporary files
        if (Test-Path $tempDir) {
            try {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            } catch {
                Write-Warning "Could not clean up temporary directory: $tempDir"
            }
        }
    }
}

# Update PATH environment variable with safety checks
function Update-Path {
    param([string]$InstallDir)
    
    # Validate input
    if ([string]::IsNullOrWhiteSpace($InstallDir)) {
        Write-Warning "Invalid installation directory provided"
        return
    }
    
    # Get current user PATH (never modify system PATH)
    try {
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    } catch {
        Write-Warning "Could not read current PATH environment variable"
        return
    }
    
    # Parse and check current PATH entries more thoroughly
    $pathEntries = if ($currentPath) { $currentPath -split ";" | Where-Object { $_ -ne "" } } else { @() }
    
    # Check if directory is already in PATH (case-insensitive, exact match)
    $alreadyInPath = $pathEntries | Where-Object { $_.TrimEnd('\') -eq $InstallDir.TrimEnd('\') }
    if ($alreadyInPath) {
        Write-Info "Directory $InstallDir is already in PATH"
        return
    }
    
    # Create backup of current PATH
    $backupKey = "PATH_BACKUP_SVG2ICON_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    try {
        [Environment]::SetEnvironmentVariable($backupKey, $currentPath, "User")
        Write-Info "PATH backup created as environment variable: $backupKey"
    } catch {
        Write-Warning "Could not create PATH backup"
    }
    
    # Safely build new PATH
    $newPathEntries = @($InstallDir) + $pathEntries
    $newPath = $newPathEntries -join ";"
    
    # Validate new PATH length (Windows has a limit)
    if ($newPath.Length -gt 2047) {
        Write-Error "New PATH would exceed Windows limit. Please manually add $InstallDir to your PATH."
        return
    }
    
    try {
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-Success "Added $InstallDir to user PATH"
        Write-Warning "Please restart your terminal or PowerShell session for PATH changes to take effect"
        
        # Also update current session PATH
        $env:PATH = "$InstallDir;$env:PATH"
        
    } catch {
        Write-Error "Failed to update PATH: $_"
        Write-Info "Please manually add $InstallDir to your PATH environment variable."
        
        # Try to restore backup if we created one
        if ($currentPath) {
            try {
                [Environment]::SetEnvironmentVariable("PATH", $currentPath, "User")
                Write-Info "PATH restored from backup"
            } catch {
                Write-Warning "Could not restore PATH backup"
            }
        }
    }
}

# Verify installation
function Test-Installation {
    param([string]$BinaryPath)
    
    if (Test-Path $BinaryPath) {
        try {
            $output = & $BinaryPath --help 2>&1
            Write-Success "Installation verified successfully!"
            Write-Info "You can now use 'svg2icon' command."
        } catch {
            Write-Warning "Binary installed but may not be working correctly."
        }
    } else {
        Write-Error "Installation failed - binary not found"
    }
}

# Create uninstaller
function New-Uninstaller {
    param(
        [string]$InstallDir,
        [string]$BinaryPath
    )
    
    $uninstallScript = @"
# svg2icon Uninstaller
Write-Host "Uninstalling svg2icon..." -ForegroundColor Yellow

# Remove binary
if (Test-Path "$BinaryPath") {
    Remove-Item "$BinaryPath" -Force
    Write-Host "Removed binary: $BinaryPath" -ForegroundColor Green
}

# Remove from PATH
`$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
`$newPath = (`$currentPath -split ";" | Where-Object { `$_ -ne "$InstallDir" }) -join ";"
[Environment]::SetEnvironmentVariable("PATH", `$newPath, "User")
Write-Host "Removed from PATH: $InstallDir" -ForegroundColor Green

# Remove installation directory if empty
if ((Test-Path "$InstallDir") -and ((Get-ChildItem "$InstallDir" | Measure-Object).Count -eq 0)) {
    Remove-Item "$InstallDir" -Force
    Write-Host "Removed installation directory: $InstallDir" -ForegroundColor Green
}

Write-Host "svg2icon uninstalled successfully!" -ForegroundColor Green
"@
    
    $uninstallPath = Join-Path $InstallDir "uninstall.ps1"
    $uninstallScript | Out-File -FilePath $uninstallPath -Encoding UTF8
    Write-Info "Created uninstaller: $uninstallPath"
}

# Main installation process
function Main {
    Write-Info "svg2icon Installation Script"
    Write-Info "============================"
    
    # Detect architecture
    $architecture = Get-Architecture
    Write-Info "Detected architecture: $architecture"
    
    # Determine installation directory
    $installDir = Get-InstallDirectory
    $binaryPath = Join-Path $installDir $BinaryName
    
    # Check if already installed
    if ((Test-Path $binaryPath) -and !$Force) {
        Write-Warning "svg2icon is already installed at $binaryPath"
        Write-Info "Use -Force to reinstall"
        return
    }
    
    # Get latest version
    $version = Get-LatestVersion
    Write-Info "Latest version: $version"
    
    # Install binary
    Install-Binary -Version $version -Architecture $architecture -InstallPath $binaryPath
    
    # Update PATH
    Update-Path -InstallDir $installDir
    
    # Create uninstaller
    New-Uninstaller -InstallDir $installDir -BinaryPath $binaryPath
    
    # Verify installation
    Test-Installation -BinaryPath $binaryPath
    
    Write-Success "svg2icon installation completed!"
    Write-Info ""
    Write-Info "Usage examples:"
    Write-Info "  svg2icon input.svg output.ico"
    Write-Info "  svg2icon input.svg output.icns"
    Write-Info "  svg2icon input.svg ./icons/"
    Write-Info ""
    Write-Info "To uninstall, run: $installDir\uninstall.ps1"
}

# Run main function
Main