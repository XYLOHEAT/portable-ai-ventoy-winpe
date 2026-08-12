[CmdletBinding()]
param(
    [ValidateSet("All", "Codex", "Claude", "OpenCode", "Crush", "Goose", "MinGit")]
    [string]$Component = "All",

    [ValidateSet("stable", "latest")]
    [string]$ClaudeChannel = "stable"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Root = $PSScriptRoot
$AppsDir = Join-Path $Root "apps"
New-Item -ItemType Directory -Force -Path $AppsDir | Out-Null

if (-not [Environment]::Is64BitOperatingSystem) {
    throw "Portable AI requires a 64-bit Windows or WinPE environment."
}

$Architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
switch ($Architecture) {
    "X64" {
        $CodexTarget = "x86_64-pc-windows-msvc"
        $ClaudePlatform = "win32-x64"
        $OpenCodeAssetName = "opencode-windows-x64-baseline.zip"
        $CrushArchitecture = "x86_64"
        $GooseAssetName = "goose-x86_64-pc-windows-msvc.zip"
        $MinGitArchitecture = "64-bit"
    }
    "Arm64" {
        $CodexTarget = "aarch64-pc-windows-msvc"
        $ClaudePlatform = "win32-arm64"
        $OpenCodeAssetName = "opencode-windows-arm64.zip"
        $CrushArchitecture = "arm64"
        $GooseAssetName = $null
        $MinGitArchitecture = "arm64"
    }
    default { throw "Unsupported architecture: $Architecture" }
}

function Get-VerifiedFile {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$OutFile,
        [Parameter(Mandatory = $true)][string]$Sha256
    )

    Invoke-WebRequest -UseBasicParsing -Uri $Uri -OutFile $OutFile
    $Actual = (Get-FileHash -LiteralPath $OutFile -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($Actual -ne $Sha256.ToLowerInvariant()) {
        Remove-Item -LiteralPath $OutFile -Force -ErrorAction SilentlyContinue
        throw "Checksum mismatch for $Uri"
    }
}

function Get-GitHubLatestRelease {
    param([Parameter(Mandatory = $true)][string]$Repository)

    Invoke-RestMethod -UseBasicParsing -Headers @{ "User-Agent" = "PortableAI-Ventoy" } -Uri "https://api.github.com/repos/$Repository/releases/latest"
}

function Get-GitHubReleaseAsset {
    param(
        [Parameter(Mandatory = $true)]$Release,
        [Parameter(Mandatory = $true)][string]$AssetName
    )

    $Asset = $Release.assets | Where-Object { $_.name -eq $AssetName } | Select-Object -First 1
    if ($null -eq $Asset) {
        throw "GitHub release $($Release.tag_name) did not contain $AssetName."
    }
    $DigestMatch = [regex]::Match([string]$Asset.digest, '^sha256:([0-9a-fA-F]{64})$')
    if (-not $DigestMatch.Success) {
        throw "GitHub release metadata did not contain a SHA-256 digest for $AssetName."
    }
    [pscustomobject]@{
        Name = [string]$Asset.name
        Uri = [string]$Asset.browser_download_url
        Sha256 = $DigestMatch.Groups[1].Value
    }
}

function Expand-VerifiedZip {
    param(
        [Parameter(Mandatory = $true)]$Asset,
        [Parameter(Mandatory = $true)][string]$TempRoot,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    $Archive = Join-Path $TempRoot $Asset.Name
    Get-VerifiedFile -Uri $Asset.Uri -OutFile $Archive -Sha256 $Asset.Sha256
    Expand-Archive -LiteralPath $Archive -DestinationPath $Destination -Force
}

function Install-DirectoryAtomically {
    param(
        [Parameter(Mandatory = $true)][string]$NewDirectory,
        [Parameter(Mandatory = $true)][string]$Destination,
        [Parameter(Mandatory = $true)][string]$TestExecutable
    )

    $Backup = "$Destination.old"
    if (Test-Path -LiteralPath $Backup) {
        Remove-Item -LiteralPath $Backup -Recurse -Force
    }
    if (Test-Path -LiteralPath $Destination) {
        Move-Item -LiteralPath $Destination -Destination $Backup
    }
    try {
        Move-Item -LiteralPath $NewDirectory -Destination $Destination
        & (Join-Path $Destination $TestExecutable) --version
        if ($LASTEXITCODE -ne 0) {
            throw "Installed executable failed its version check."
        }
        if (Test-Path -LiteralPath $Backup) {
            Remove-Item -LiteralPath $Backup -Recurse -Force
        }
    }
    catch {
        if (Test-Path -LiteralPath $Destination) {
            Remove-Item -LiteralPath $Destination -Recurse -Force
        }
        if (Test-Path -LiteralPath $Backup) {
            Move-Item -LiteralPath $Backup -Destination $Destination
        }
        throw
    }
}

function Install-CodexPortable {
    Write-Host "==> Resolving latest stable Codex release"
    $Release = Invoke-RestMethod -Uri "https://releases.openai.com/codex/channels/latest"
    $AssetName = "codex-package-$CodexTarget.tar.gz"
    $Asset = $Release.assets | Where-Object { $_.name -eq $AssetName } | Select-Object -First 1
    if ($null -eq $Asset) {
        throw "Codex release metadata did not contain $AssetName with a SHA-256 digest."
    }
    $DigestMatch = [regex]::Match([string]$Asset.digest, '^sha256:([0-9a-fA-F]{64})$')
    if (-not $DigestMatch.Success) {
        throw "Codex release metadata did not contain $AssetName with a SHA-256 digest."
    }
    $ExpectedHash = $DigestMatch.Groups[1].Value
    $TempRoot = Join-Path ([IO.Path]::GetTempPath()) ("portable-codex-" + [guid]::NewGuid().ToString("N"))
    $Archive = Join-Path $TempRoot $AssetName
    $Staging = Join-Path $AppsDir "codex.new"
    New-Item -ItemType Directory -Force -Path $TempRoot | Out-Null
    try {
        Write-Host "==> Downloading Codex $($Release.tag_name)"
        Get-VerifiedFile -Uri ([string]$Asset.browser_download_url) -OutFile $Archive -Sha256 $ExpectedHash
        $Tar = Get-Command tar.exe -ErrorAction SilentlyContinue
        if ($null -eq $Tar) { $Tar = Get-Command tar -ErrorAction SilentlyContinue }
        if ($null -eq $Tar) { throw "tar.exe is required. Run this updater on full Windows 10/11." }
        if (Test-Path -LiteralPath $Staging) { Remove-Item -LiteralPath $Staging -Recurse -Force }
        New-Item -ItemType Directory -Force -Path $Staging | Out-Null
        & $Tar.Source -xzf $Archive -C $Staging
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath (Join-Path $Staging "bin\codex.exe"))) {
            throw "Could not extract the Codex package."
        }
        Set-Content -LiteralPath (Join-Path $Staging "PORTABLE-VERSION.txt") -Value ([string]$Release.tag_name) -Encoding ASCII
        Install-DirectoryAtomically -NewDirectory $Staging -Destination (Join-Path $AppsDir "codex") -TestExecutable "bin\codex.exe"
    }
    finally {
        Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $Staging -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Install-ClaudePortable {
    $BaseUri = "https://downloads.claude.ai/claude-code-releases"
    Write-Host "==> Resolving Claude Code $ClaudeChannel release"
    $Version = ([string](Invoke-RestMethod -Uri "$BaseUri/$ClaudeChannel")).Trim()
    if ($Version -notmatch '^\d+\.\d+\.\d+') { throw "Invalid Claude Code version: $Version" }
    $Manifest = Invoke-RestMethod -Uri "$BaseUri/$Version/manifest.json"
    $PlatformEntry = $Manifest.platforms.$ClaudePlatform
    if ($null -eq $PlatformEntry -or [string]$PlatformEntry.checksum -notmatch '^[0-9a-fA-F]{64}$') {
        throw "Claude Code manifest did not contain $ClaudePlatform with a SHA-256 checksum."
    }
    $Staging = Join-Path $AppsDir "claude.new"
    if (Test-Path -LiteralPath $Staging) { Remove-Item -LiteralPath $Staging -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $Staging | Out-Null
    try {
        Write-Host "==> Downloading Claude Code $Version ($ClaudePlatform)"
        $ClaudeExe = Join-Path $Staging "claude.exe"
        Get-VerifiedFile -Uri "$BaseUri/$Version/$ClaudePlatform/claude.exe" -OutFile $ClaudeExe -Sha256 ([string]$PlatformEntry.checksum)
        Set-Content -LiteralPath (Join-Path $Staging "PORTABLE-VERSION.txt") -Value $Version -Encoding ASCII
        Install-DirectoryAtomically -NewDirectory $Staging -Destination (Join-Path $AppsDir "claude") -TestExecutable "claude.exe"
    }
    finally {
        Remove-Item -LiteralPath $Staging -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Install-OpenCodePortable {
    Write-Host "==> Resolving latest stable OpenCode release"
    $Release = Get-GitHubLatestRelease -Repository "anomalyco/opencode"
    $Asset = Get-GitHubReleaseAsset -Release $Release -AssetName $OpenCodeAssetName
    $TempRoot = Join-Path ([IO.Path]::GetTempPath()) ("portable-opencode-" + [guid]::NewGuid().ToString("N"))
    $Staging = Join-Path $AppsDir "opencode.new"
    New-Item -ItemType Directory -Force -Path $TempRoot | Out-Null
    try {
        Write-Host "==> Downloading OpenCode $($Release.tag_name)"
        if (Test-Path -LiteralPath $Staging) { Remove-Item -LiteralPath $Staging -Recurse -Force }
        New-Item -ItemType Directory -Force -Path $Staging | Out-Null
        Expand-VerifiedZip -Asset $Asset -TempRoot $TempRoot -Destination $Staging
        if (-not (Test-Path -LiteralPath (Join-Path $Staging "opencode.exe"))) {
            throw "Could not extract the OpenCode package."
        }
        Set-Content -LiteralPath (Join-Path $Staging "PORTABLE-VERSION.txt") -Value ([string]$Release.tag_name) -Encoding ASCII
        Install-DirectoryAtomically -NewDirectory $Staging -Destination (Join-Path $AppsDir "opencode") -TestExecutable "opencode.exe"
    }
    finally {
        Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $Staging -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Install-CrushPortable {
    Write-Host "==> Resolving latest stable Crush release"
    $Release = Get-GitHubLatestRelease -Repository "charmbracelet/crush"
    $Version = ([string]$Release.tag_name).TrimStart("v")
    $AssetName = "crush_${Version}_Windows_${CrushArchitecture}.zip"
    $Asset = Get-GitHubReleaseAsset -Release $Release -AssetName $AssetName
    $TempRoot = Join-Path ([IO.Path]::GetTempPath()) ("portable-crush-" + [guid]::NewGuid().ToString("N"))
    $Extracted = Join-Path $TempRoot "extracted"
    $Staging = Join-Path $AppsDir "crush.new"
    New-Item -ItemType Directory -Force -Path $Extracted | Out-Null
    try {
        Write-Host "==> Downloading Crush $($Release.tag_name)"
        Expand-VerifiedZip -Asset $Asset -TempRoot $TempRoot -Destination $Extracted
        $CrushExe = Get-ChildItem -LiteralPath $Extracted -Recurse -File -Filter "crush.exe" | Select-Object -First 1
        if ($null -eq $CrushExe) { throw "Could not extract the Crush package." }
        if (Test-Path -LiteralPath $Staging) { Remove-Item -LiteralPath $Staging -Recurse -Force }
        New-Item -ItemType Directory -Force -Path $Staging | Out-Null
        Copy-Item -LiteralPath $CrushExe.FullName -Destination (Join-Path $Staging "crush.exe")
        $License = Join-Path $CrushExe.Directory.FullName "LICENSE.md"
        if (Test-Path -LiteralPath $License) { Copy-Item -LiteralPath $License -Destination (Join-Path $Staging "LICENSE.md") }
        Set-Content -LiteralPath (Join-Path $Staging "PORTABLE-VERSION.txt") -Value ([string]$Release.tag_name) -Encoding ASCII
        Install-DirectoryAtomically -NewDirectory $Staging -Destination (Join-Path $AppsDir "crush") -TestExecutable "crush.exe"
    }
    finally {
        Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $Staging -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Install-GoosePortable {
    if ($null -eq $GooseAssetName) {
        throw "Goose does not currently publish a native Windows ARM64 CLI asset."
    }
    Write-Host "==> Resolving latest stable Goose release"
    $Release = Get-GitHubLatestRelease -Repository "aaif-goose/goose"
    $Asset = Get-GitHubReleaseAsset -Release $Release -AssetName $GooseAssetName
    $TempRoot = Join-Path ([IO.Path]::GetTempPath()) ("portable-goose-" + [guid]::NewGuid().ToString("N"))
    $Extracted = Join-Path $TempRoot "extracted"
    $Staging = Join-Path $AppsDir "goose.new"
    New-Item -ItemType Directory -Force -Path $Extracted | Out-Null
    try {
        Write-Host "==> Downloading Goose $($Release.tag_name)"
        Expand-VerifiedZip -Asset $Asset -TempRoot $TempRoot -Destination $Extracted
        $GooseExe = Get-ChildItem -LiteralPath $Extracted -Recurse -File -Filter "goose.exe" | Select-Object -First 1
        if ($null -eq $GooseExe) { throw "Could not extract the Goose package." }
        if (Test-Path -LiteralPath $Staging) { Remove-Item -LiteralPath $Staging -Recurse -Force }
        New-Item -ItemType Directory -Force -Path $Staging | Out-Null
        Copy-Item -LiteralPath $GooseExe.FullName -Destination (Join-Path $Staging "goose.exe")
        Set-Content -LiteralPath (Join-Path $Staging "PORTABLE-VERSION.txt") -Value ([string]$Release.tag_name) -Encoding ASCII
        Install-DirectoryAtomically -NewDirectory $Staging -Destination (Join-Path $AppsDir "goose") -TestExecutable "goose.exe"
    }
    finally {
        Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $Staging -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Install-MinGitPortable {
    Write-Host "==> Resolving latest stable Git for Windows release"
    $Release = Get-GitHubLatestRelease -Repository "git-for-windows/git"
    $Version = (([string]$Release.tag_name).TrimStart("v")) -replace '\.windows\.', '.'
    $AssetName = "MinGit-$Version-$MinGitArchitecture.zip"
    $Asset = Get-GitHubReleaseAsset -Release $Release -AssetName $AssetName
    $TempRoot = Join-Path ([IO.Path]::GetTempPath()) ("portable-mingit-" + [guid]::NewGuid().ToString("N"))
    $Staging = Join-Path $AppsDir "mingit.new"
    New-Item -ItemType Directory -Force -Path $TempRoot | Out-Null
    try {
        Write-Host "==> Downloading MinGit $($Release.tag_name)"
        if (Test-Path -LiteralPath $Staging) { Remove-Item -LiteralPath $Staging -Recurse -Force }
        New-Item -ItemType Directory -Force -Path $Staging | Out-Null
        Expand-VerifiedZip -Asset $Asset -TempRoot $TempRoot -Destination $Staging
        if (-not (Test-Path -LiteralPath (Join-Path $Staging "cmd\git.exe"))) {
            throw "Could not extract the MinGit package."
        }
        Set-Content -LiteralPath (Join-Path $Staging "PORTABLE-VERSION.txt") -Value ([string]$Release.tag_name) -Encoding ASCII
        Install-DirectoryAtomically -NewDirectory $Staging -Destination (Join-Path $AppsDir "mingit") -TestExecutable "cmd\git.exe"
    }
    finally {
        Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $Staging -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($Component -eq "All" -or $Component -eq "MinGit") { Install-MinGitPortable }
if ($Component -eq "All" -or $Component -eq "Codex") { Install-CodexPortable }
if ($Component -eq "All" -or $Component -eq "Claude") { Install-ClaudePortable }
if ($Component -eq "All" -or $Component -eq "OpenCode") { Install-OpenCodePortable }
if ($Component -eq "All" -or $Component -eq "Crush") { Install-CrushPortable }
if ($Component -eq "Goose") { Install-GoosePortable }
if ($Component -eq "All" -and $null -ne $GooseAssetName) { Install-GoosePortable }
if ($Component -eq "All" -and $null -eq $GooseAssetName) { Write-Warning "Skipping Goose: no native Windows ARM64 CLI asset is available." }

Write-Host ""
Write-Host "Portable AI update complete."
Write-Host "Launch: $Root\PortableAI.cmd"
