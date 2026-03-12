<#PSScriptInfo

.VERSION 0.1.0

.GUID a4af5e07-d626-4b97-b4d6-eef7265d1f7c

.AUTHOR asheroto

.COMPANYNAME asheroto

.TAGS PowerShell speedtest speed test speedtest.net

.PROJECTURI https://github.com/asheroto/speedtest

.RELEASENOTES
[Version 0.0.1] - Initial Release.
[Version 0.0.2] - Added UseBasicParsing parameter to Invoke-WebRequest commands to fix issue with certain systems.
[Version 0.0.3] - Adjusted to work with GDPR acceptance.
[Version 0.1.0] - Added cross-platform support for Windows, Linux (x86_64 and aarch64), and macOS.

#>

<#
.SYNOPSIS
	Downloads and runs the Speedtest.net CLI client.
.DESCRIPTION
	Downloads and runs the Speedtest.net CLI client.

Designed to use with short URL to make it easy to remember.
Supports Windows (x64/arm64), Linux (x86_64/aarch64), and macOS (Intel/Apple Silicon).
.EXAMPLE
	speedtest.ps1
.PARAMETER Version
    Displays the version of the script.
.PARAMETER Help
    Displays the full help information for the script.
.NOTES
	Version      : 0.1.0
	Created by   : asheroto
.LINK
	Project Site: https://github.com/asheroto/speedtest
#>
param (
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$ScriptArgs
)

# Version
$CurrentVersion = '0.1.0'
$RepoOwner = 'asheroto'
$RepoName = 'speedtest'
$PowerShellGalleryName = 'speedtest'

# Versions
$ProgressPreference = 'SilentlyContinue' # Suppress progress bar (makes downloading super fast)
$ConfirmPreference = 'None' # Suppress confirmation prompts

# Display version if -Version is specified
if ($Version.IsPresent) {
    $CurrentVersion
    exit 0
}

# Display full help if -Help is specified
if ($Help) {
    Get-Help -Name $MyInvocation.MyCommand.Source -Full
    exit 0
}

# Display $PSVersionTable and Get-Host if -Verbose is specified
if ($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters['Verbose']) {
    $PSVersionTable
    Get-Host
}

# ============================================================================ #
# Platform Detection
# ============================================================================ #

function Get-OS {
    # $IsWindows is not defined in Windows PowerShell 5.1, only in PowerShell Core 6+
    if ($PSVersionTable.PSEdition -eq 'Desktop') {
        return 'Windows'
    } elseif ($IsWindows) {
        return 'Windows'
    } elseif ($IsLinux) {
        return 'Linux'
    } elseif ($IsMacOS) {
        return 'macOS'
    } else {
        throw "Unsupported operating system."
    }
}

function Get-Arch {
    param ([string]$OS)
    # Windows only ships a single win64 build — arch detection not needed
    if ($OS -eq 'Windows') { return 'x64' }
    # Linux and macOS ship separate builds per architecture
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
    switch ($arch) {
        'X64'   { return 'x86_64' }
        'Arm64' { return 'aarch64' }
        default { return 'x86_64' }
    }
}

function Get-TempFolder {
    if ($env:TEMP) {
        return $env:TEMP
    } elseif ($env:TMPDIR) {
        return $env:TMPDIR.TrimEnd('/')
    } else {
        return '/tmp'
    }
}

# ============================================================================ #
# Startup
# ============================================================================ #

# Scrape the webpage to get the download link for the appropriate platform
function Get-SpeedTestDownloadLink {
    param (
        [string]$OS,
        [string]$Arch
    )

    $url = "https://www.speedtest.net/apps/cli"
    $webContent = Invoke-WebRequest -Uri $url -UseBasicParsing

    switch ($OS) {
        'Windows' {
            if ($webContent.Content -match 'href="(https://install\.speedtest\.net/app/cli/ookla-speedtest-[\d\.]+-win64\.zip)"') {
                return $matches[1]
            }
        }
        'Linux' {
            # Try the exact architecture first, fall back to x86_64
            $archSuffix = if ($Arch -eq 'aarch64') { 'aarch64' } else { 'x86_64' }
            if ($webContent.Content -match "href=`"(https://install\.speedtest\.net/app/cli/ookla-speedtest-[\d\.]+-linux-$archSuffix\.tgz)`"") {
                return $matches[1]
            }
            # Fallback to x86_64 if aarch64 not found
            if ($archSuffix -ne 'x86_64' -and $webContent.Content -match 'href="(https://install\.speedtest\.net/app/cli/ookla-speedtest-[\d\.]+-linux-x86_64\.tgz)"') {
                Write-Warning "Could not find aarch64 build, falling back to x86_64."
                return $matches[1]
            }
        }
        'macOS' {
            # Try ARM64 first for Apple Silicon, then fall back to universal/x86_64
            if ($Arch -eq 'aarch64' -and $webContent.Content -match 'href="(https://install\.speedtest\.net/app/cli/ookla-speedtest-[\d\.]+-macosx-arm64\.tgz)"') {
                return $matches[1]
            }
            if ($webContent.Content -match 'href="(https://install\.speedtest\.net/app/cli/ookla-speedtest-[\d\.]+-macosx\.tgz)"') {
                return $matches[1]
            }
        }
    }

    Write-Output "Unable to find the download link for $OS ($Arch)."
    return $null
}

# Download the archive file
function Download-SpeedTestArchive {
    param (
        [string]$downloadLink,
        [string]$destination
    )
    Invoke-WebRequest -Uri $downloadLink -OutFile $destination -UseBasicParsing
}

# Extract the archive (zip on Windows, tgz on Linux/macOS)
function Extract-Archive {
    param (
        [string]$archivePath,
        [string]$destination,
        [string]$OS
    )

    if (-not (Test-Path $destination)) {
        New-Item -ItemType Directory -Path $destination | Out-Null
    }

    if ($OS -eq 'Windows') {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($archivePath, $destination)
    } else {
        # Linux and macOS use tgz; invoke tar which is available on both
        $result = & tar -xzf $archivePath -C $destination
        if ($LASTEXITCODE -ne 0) {
            throw "tar extraction failed with exit code $LASTEXITCODE."
        }
    }
}

# Run the speedtest executable
function Run-SpeedTest {
    param (
        [string]$executablePath,
        [array]$arguments
    )

    # Check if '--accept-license' is already in arguments
    if (-not ($arguments -contains "--accept-license")) {
        $arguments += "--accept-license"
    }

    # Check if '--accept-gdpr' is already in arguments
    if (-not ($arguments -contains "--accept-gdpr")) {
        $arguments += "--accept-gdpr"
    }

    & $executablePath $arguments
}


# Cleanup
function Remove-File {
    param (
        [string]$Path
    )
    try {
        if (Test-Path -Path $Path) {
            Remove-Item -Path $Path -Recurse -ErrorAction Stop
        }
    } catch {
        Write-Debug "Unable to remove item: $_"
    }
}

function Remove-Files {
    param(
        [string]$archivePath,
        [string]$folderPath
    )
    Remove-File -Path $archivePath
    Remove-File -Path $folderPath
}

# Main Script
try {
    $os   = Get-OS
    $arch = Get-Arch -OS $os
    $tempFolder = Get-TempFolder

    # Determine archive extension and executable name based on OS
    $archiveExt    = if ($os -eq 'Windows') { 'zip' } else { 'tgz' }
    $executableName = if ($os -eq 'Windows') { 'speedtest.exe' } else { 'speedtest' }

    $archiveTag      = "$($os.ToLower())-$arch"
    $archiveFilePath = Join-Path $tempFolder "speedtest-$archiveTag.$archiveExt"
    $extractFolder   = Join-Path $tempFolder "speedtest-$archiveTag"

    Remove-Files -archivePath $archiveFilePath -folderPath $extractFolder

    $platformLabel = if ($os -eq 'Windows') { $os } else { "$os ($arch)" }
    Write-Output "Detected platform: $platformLabel"

    $downloadLink = Get-SpeedTestDownloadLink -OS $os -Arch $arch
    if (-not $downloadLink) {
        throw "Could not determine download link for $os ($arch)."
    }

    Write-Output "Downloading SpeedTest CLI..."
    Download-SpeedTestArchive -downloadLink $downloadLink -destination $archiveFilePath

    Write-Output "Extracting archive..."
    Extract-Archive -archivePath $archiveFilePath -destination $extractFolder -OS $os

    $executablePath = Join-Path $extractFolder $executableName

    # On Linux/macOS ensure the binary is executable
    if ($os -ne 'Windows') {
        & chmod +x $executablePath
    }

    Write-Output "Running SpeedTest..."
    Run-SpeedTest -executablePath $executablePath -arguments $ScriptArgs

    Write-Output "Cleaning up..."
    Remove-Files -archivePath $archiveFilePath -folderPath $extractFolder

    Write-Output "Done."
} catch {
    Write-Error "An error occurred: $_"
}
