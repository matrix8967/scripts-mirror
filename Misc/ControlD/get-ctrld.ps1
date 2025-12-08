#!/usr/bin/env pwsh
param()

$ErrorActionPreference = "Stop"

### ---------------------------------------------
### Globals
### ---------------------------------------------
$Version = "latest"
$Install = $false
$VerboseOutput = $false

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
  --version <tag>   Specify version (e.g. v1.4.8). Default: latest release.
  --install         Install ctrld.exe into C:\Program Files\ctrld\
  --verbose         Enable verbose logging.
  -h, --help        Show this help message.

Examples:
  $ScriptName
      Downloads latest ctrld and extracts it.

  $ScriptName --version v1.4.8 --install
      Downloads, verifies SHA256, extracts, and installs.

Notes:
  • The Windows ZIP contains a deep folder like:
        dist/ctrld_<version>_windows_amd64/ctrld.exe
    This script automatically finds it.
"@
}

### ---------------------------------------------
### LOGGING
### ---------------------------------------------
function Log { param($m) Write-Host "[INFO] $m" }
function Err { param($m) Write-Host "[ERROR] $m" -ForegroundColor Red }

### ---------------------------------------------
### ARG PARSING
### ---------------------------------------------
for ($i = 0; $i -lt $args.Length; $i++) {
    switch ($args[$i]) {
        "--version" {
            $Version = $args[$i+1]
            $i++
        }
        "--install" { $Install = $true }
        "--verbose" { $VerboseOutput = $true }
        "-h" { Show-Help; exit }
        "--help" { Show-Help; exit }
        default {
            Err "Unknown flag: $($args[$i])"
            exit 1
        }
    }
}

### ---------------------------------------------
### Architecture
### ---------------------------------------------
$Arch = (Get-CimInstance Win32_Processor).Architecture
switch ($Arch) {
    9 { $Arch = "amd64" }
    default { Err "Unsupported architecture"; exit 1 }
}

$OS = "windows"

### ---------------------------------------------
### Version resolution
### ---------------------------------------------
if ($Version -eq "latest") {
    $LatestTag = Invoke-RestMethod -Uri "https://api.github.com/repos/Control-D-Inc/ctrld/releases/latest"
    $Version = $LatestTag.tag_name
}

Log "OS: $OS"
Log "ARCH: $Arch"
Log "Version: $Version"

### ---------------------------------------------
### Fetch release metadata
### ---------------------------------------------
$ReleaseUrl = "https://api.github.com/repos/Control-D-Inc/ctrld/releases/tags/$Version"
$Release = Invoke-RestMethod -Uri $ReleaseUrl

$Asset = $Release.assets | Where-Object {
    $_.name -match "windows" -and $_.name -match $Arch
}

if (-not $Asset) {
    Err "No Windows asset found for version $Version"
    exit 1
}

$Checksums = $Release.assets | Where-Object { $_.name -eq "checksums.txt" }

$ArchiveUrl = $Asset.browser_download_url
$ChecksumUrl = $Checksums.browser_download_url

$ArchiveName = $Asset.name
$ChecksumFile = "checksums.txt"

Log "Asset URL: $ArchiveUrl"
Log "Checksums URL: $ChecksumUrl"

### ---------------------------------------------
### Download
### ---------------------------------------------
Invoke-WebRequest -Uri $ArchiveUrl -OutFile $ArchiveName
Invoke-WebRequest -Uri $ChecksumUrl -OutFile $ChecksumFile

Log "Downloads complete."

### ---------------------------------------------
### VERIFY CHECKSUM
### ---------------------------------------------
$SelectedLine = Select-String -Path $ChecksumFile -Pattern ([regex]::Escape($ArchiveName)) | Select-Object -First 1
if (-not $SelectedLine) {
    Err "Checksum entry not found!"
    exit 1
}

$Expected = $SelectedLine.Line.Split(" ")[0]
$Actual = (Get-FileHash $ArchiveName -Algorithm SHA256).Hash.ToLower()

if ($Expected -ne $Actual) {
    Err "Checksum mismatch!"
    exit 1
}

Log "Checksum OK."

### ---------------------------------------------
### EXTRACT ZIP
### ---------------------------------------------
$ExtractDir = "ctrld_extract"
if (Test-Path $ExtractDir) { Remove-Item $ExtractDir -Recurse -Force }
New-Item -ItemType Directory -Path $ExtractDir | Out-Null

Expand-Archive -Path $ArchiveName -DestinationPath $ExtractDir -Force

### Find the nested binary
$Bin = Get-ChildItem -Path $ExtractDir -Recurse -Filter ctrld.exe | Select-Object -First 1
if (-not $Bin) {
    Err "ctrld.exe not found in archive!"
    exit 1
}

Log "Found binary at: $($Bin.FullName)"

### ---------------------------------------------
### INSTALL (OPTIONAL)
### ---------------------------------------------
if ($Install) {
    $TargetDir = "C:\Program Files\ctrld"
    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir | Out-Null
    }

    Log "Installing to: $TargetDir"
    Copy-Item $Bin.FullName "$TargetDir\ctrld.exe" -Force
}

Log "Done."
