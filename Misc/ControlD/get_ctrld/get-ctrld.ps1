#!/usr/bin/env pwsh
param()

$ErrorActionPreference = "Stop"

# Force TLS 1.2 (older PowerShell/.NET defaults on some Windows Server /
# Windows 10 builds don't include it, which breaks requests to GitHub's API
# with an opaque SSL/TLS error). OR'd in rather than overwritten so any
# other already-enabled protocols aren't clobbered.
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch {
    # Ignore on runtimes where Tls12 isn't a defined enum member
}

$Repo = "Control-D-Inc/ctrld"

### ---------------------------------------------
### Globals
### ---------------------------------------------
$Version = "latest"
$Install = $false
$VerboseOutput = $false
$ListReleases = $false
$CheckOnly = $false

$ScriptName = Split-Path -Leaf $PSCommandPath

### ---------------------------------------------
### HELP
### ---------------------------------------------
function Show-Help {
@"
Usage: $ScriptName [OPTIONS]

Download (and optionally install) the latest or a specific version of the
ControlD ctrld binary for Windows.

Options:
  --version <tag>   Specify version (e.g. v1.4.8 or 1.4.8). Default: latest release.
  --install         Install ctrld.exe into C:\Program Files\ctrld\
  --list            List available release tags (most recent first)
  --check           Dry-run: print detected OS/arch and download URL, then exit
  --verbose         Enable verbose logging.
  -h, --help        Show this help message.

Examples:
  $ScriptName
      Downloads latest ctrld and extracts it.

  $ScriptName --version 1.4.8 --install
      Downloads, verifies SHA256, extracts, and installs.

  $ScriptName --list
      Lists available release tags.

  $ScriptName --check
      Shows what would be downloaded without downloading anything.

Notes:
  - The Windows ZIP contains a deep folder like:
        dist/ctrld_<version>_windows_amd64/ctrld.exe
    This script automatically finds it.
  - Supported architectures: amd64, arm64, 386 (x86)
"@
}

### ---------------------------------------------
### LOGGING
### ---------------------------------------------
function Log     { param($m) Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn    { param($m) Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Err     { param($m) Write-Host "[ERROR] $m" -ForegroundColor Red }
function Success { param($m) Write-Host "[SUCCESS] $m" -ForegroundColor Green }

### ---------------------------------------------
### ARG PARSING
### ---------------------------------------------
for ($i = 0; $i -lt $args.Length; $i++) {
    switch ($args[$i]) {
        "--version" {
            if ($i + 1 -ge $args.Length) { Err "Value expected for --version"; exit 1 }
            $Version = $args[$i + 1]
            $i++
        }
        "--install"  { $Install = $true }
        "--list"     { $ListReleases = $true }
        "--check"    { $CheckOnly = $true }
        "--verbose"  { $VerboseOutput = $true }
        "-h"         { Show-Help; exit 0 }
        "--help"     { Show-Help; exit 0 }
        default {
            Err "Unknown flag: $($args[$i])"
            exit 1
        }
    }
}

# Normalize version string (accept with or without leading "v")
$Version = $Version -replace '^v', ''

### ---------------------------------------------
### List releases
### ---------------------------------------------
if ($ListReleases) {
    try {
        $Releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases"
    } catch {
        Err "Failed to query releases: $($_.Exception.Message)"
        exit 1
    }

    $Releases |
        ForEach-Object { $_.tag_name -replace '^v', '' } |
        Sort-Object -Property @{ Expression = { try { [version]$_ } catch { [version]"0.0.0" } } } -Descending

    exit 0
}

### ---------------------------------------------
### Architecture detection
### ---------------------------------------------
$ArchCode = (Get-CimInstance Win32_Processor).Architecture
# Some multi-socket systems (e.g. server hardware) can return an array, one
# value per physical CPU -- take the first since they'll all match anyway.
if ($ArchCode -is [array]) { $ArchCode = $ArchCode[0] }

switch ($ArchCode) {
    9  { $Arch = "amd64" }   # x64
    12 { $Arch = "arm64" }   # ARM64
    0  { $Arch = "386" }     # x86
    default {
        Err "Unsupported architecture (WMI Architecture code: $ArchCode)"
        exit 1
    }
}

$OS = "windows"

Log "OS: $OS"
Log "ARCH: $Arch"
Log "Version: $(if ($Version -eq 'latest') { 'latest' } else { "v$Version" })"

### ---------------------------------------------
### Fetch release metadata (single call, reused for "latest" or a pinned tag)
### ---------------------------------------------
if ($Version -eq "latest") {
    $ReleaseUrl = "https://api.github.com/repos/$Repo/releases/latest"
} else {
    $ReleaseUrl = "https://api.github.com/repos/$Repo/releases/tags/v$Version"
}

try {
    $Release = Invoke-RestMethod -Uri $ReleaseUrl
} catch {
    Err "Failed to query release info ($ReleaseUrl): $($_.Exception.Message)"
    exit 1
}

$Version = $Release.tag_name -replace '^v', ''

$Asset = $Release.assets | Where-Object {
    $_.name -match "windows" -and $_.name -match [regex]::Escape($Arch)
} | Select-Object -First 1

if (-not $Asset) {
    Err "No Windows asset found for version v$Version (arch: $Arch)"
    exit 1
}

$Checksums = $Release.assets | Where-Object { $_.name -match "checksums|sha256" } | Select-Object -First 1

$ArchiveUrl = $Asset.browser_download_url
$ArchiveName = $Asset.name

if ($CheckOnly) {
    Write-Host "DRY RUN:"
    Write-Host "  OS:        $OS"
    Write-Host "  Arch:      $Arch"
    Write-Host "  Version:   v$Version"
    Write-Host "  URL:       $ArchiveUrl"
    if ($Checksums) { Write-Host "  Checksums: $($Checksums.browser_download_url)" }
    exit 0
}

Log "Asset URL: $ArchiveUrl"
if ($Checksums) {
    Log "Checksums URL: $($Checksums.browser_download_url)"
} else {
    Warn "No checksums asset found for this release; skipping verification."
}

### ---------------------------------------------
### Download / verify / extract / install
### (wrapped for guaranteed temp-dir cleanup, regardless of outcome)
### ---------------------------------------------
$ExitCode = 0
$TmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("ctrld_" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $TmpDir | Out-Null

try {
    $ArchivePath = Join-Path $TmpDir $ArchiveName

    ### Download
    try {
        Invoke-WebRequest -Uri $ArchiveUrl -OutFile $ArchivePath
    } catch {
        throw "Download failed ($ArchiveUrl): $($_.Exception.Message)"
    }

    $ChecksumPath = $null
    if ($Checksums) {
        $ChecksumPath = Join-Path $TmpDir "checksums.txt"
        try {
            Invoke-WebRequest -Uri $Checksums.browser_download_url -OutFile $ChecksumPath
        } catch {
            Warn "Failed to download checksums; continuing without verification."
            $ChecksumPath = $null
        }
    }

    Log "Download complete."

    ### Verify checksum (if we have one)
    if ($ChecksumPath -and (Test-Path $ChecksumPath)) {
        $SelectedLine = Select-String -Path $ChecksumPath -Pattern ([regex]::Escape($ArchiveName)) | Select-Object -First 1
        if (-not $SelectedLine) {
            Warn "Checksums file present but no entry for $ArchiveName; skipping verification."
        } else {
            $Expected = ($SelectedLine.Line.Split(" ")[0]).ToLower()
            $Actual = (Get-FileHash $ArchivePath -Algorithm SHA256).Hash.ToLower()

            if ($Expected -ne $Actual) {
                throw "Checksum mismatch! expected:$Expected actual:$Actual"
            }
            Log "Checksum OK."
        }
    } else {
        Warn "No checksums file -- skipping checksum verification."
    }

    ### Extract ZIP
    $ExtractDir = Join-Path $TmpDir "extract"
    New-Item -ItemType Directory -Path $ExtractDir | Out-Null

    Expand-Archive -Path $ArchivePath -DestinationPath $ExtractDir -Force

    $Bin = Get-ChildItem -Path $ExtractDir -Recurse -Filter ctrld.exe | Select-Object -First 1
    if (-not $Bin) {
        throw "ctrld.exe not found in archive!"
    }

    Log "Extracted binary: $($Bin.FullName)"

    ### Install (optional)
    if ($Install) {
        $TargetDir = "C:\Program Files\ctrld"
        if (-not (Test-Path $TargetDir)) {
            New-Item -ItemType Directory -Path $TargetDir | Out-Null
        }

        $TargetPath = Join-Path $TargetDir "ctrld.exe"
        Log "Installing to: $TargetPath"
        Copy-Item $Bin.FullName $TargetPath -Force
        Success "Installed: $TargetPath"

        try {
            & $TargetPath --version 2>$null
        } catch { }

        Write-Host ""
        Write-Host "Next steps:"
        Write-Host "  1. Run initial setup:"
        Write-Host "       & '$TargetPath' start"
        Write-Host "  2. Check for a service-install subcommand (varies by ctrld version):"
        Write-Host "       & '$TargetPath' --help"
        Write-Host ""
        Write-Host "For more info: https://docs.controld.com/docs/installation-windows"
    } else {
        # Not installing -- relocate the binary out of the temp dir before
        # it's cleaned up below, so the user is actually left with something.
        $DestPath = Join-Path (Get-Location) "ctrld.exe"
        Copy-Item $Bin.FullName $DestPath -Force
        Log "Install skipped. Binary available at: $DestPath"
    }
}
catch {
    Err $_.Exception.Message
    $ExitCode = 1
}
finally {
    if (Test-Path $TmpDir) {
        Remove-Item $TmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($ExitCode -eq 0) {
    Success "Done."
}
exit $ExitCode
