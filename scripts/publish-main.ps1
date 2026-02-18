param(
  [string]$RepoUrl = "https://github.com/fake-cmd/the-SHS-bypass.git",
  [string]$Branch = "main",
  [string]$CloneDir = "$env:USERPROFILE\the-SHS-bypass"
)

$ErrorActionPreference = "Stop"

function Get-GitCommand {
  $gitCmd = Get-Command git -ErrorAction SilentlyContinue
  if ($gitCmd) {
    return $gitCmd.Source
  }

  Write-Host "git was not found. Installing portable MinGit (no admin) ..." -ForegroundColor Yellow

  $installRoot = Join-Path $env:LOCALAPPDATA "Programs\MinGit"
  $zipPath = Join-Path $env:TEMP "mingit.zip"

  if (!(Test-Path $installRoot)) {
    New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
  }

  $release = Invoke-RestMethod "https://api.github.com/repos/git-for-windows/git/releases/latest"
  $asset = $release.assets |
    Where-Object { $_.name -match '^MinGit-.*-64-bit.zip$' } |
    Select-Object -First 1

  if (-not $asset) {
    throw "Could not find a MinGit 64-bit release asset."
  }

  Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath

  if (Test-Path (Join-Path $installRoot "cmd")) {
    Remove-Item -Recurse -Force $installRoot
    New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
  }

  Expand-Archive -Path $zipPath -DestinationPath $installRoot -Force

  $gitExe = Join-Path $installRoot "cmd\git.exe"
  if (!(Test-Path $gitExe)) {
    throw "Portable git install failed: $gitExe not found."
  }

  $env:PATH = "$($installRoot)\cmd;$env:PATH"
  Write-Host "Portable git installed at: $installRoot" -ForegroundColor Green
  return $gitExe
}

function Invoke-Git {
  param([string[]]$Args)

  & $script:GitExe @Args
  if ($LASTEXITCODE -ne 0) {
    throw "git $($Args -join ' ') failed with exit code $LASTEXITCODE"
  }
}

$script:GitExe = Get-GitCommand
Write-Host "Using git: $script:GitExe" -ForegroundColor Cyan

$inGitRepo = $false
try {
  & $script:GitExe rev-parse --is-inside-work-tree *> $null
  if ($LASTEXITCODE -eq 0) { $inGitRepo = $true }
} catch {
  $inGitRepo = $false
}

if (-not $inGitRepo) {
  Write-Host "Not inside a git repo. Cloning to $CloneDir ..." -ForegroundColor Yellow
  if (!(Test-Path $CloneDir)) {
    Invoke-Git @("clone", $RepoUrl, $CloneDir)
  }
  Set-Location $CloneDir
} else {
  Write-Host "Detected existing git repository: $(Get-Location)" -ForegroundColor Cyan
}

Invoke-Git @("remote", "set-url", "origin", $RepoUrl)
Invoke-Git @("checkout", "-B", $Branch)

$changes = & $script:GitExe status --porcelain
if ($changes) {
  Write-Host "Committing local changes before push ..." -ForegroundColor Yellow
  Invoke-Git @("add", "-A")
  try {
    Invoke-Git @("commit", "-m", "chore: publish latest updates")
  } catch {
    Write-Host "No commit created (possibly no staged changes). Continuing ..." -ForegroundColor Yellow
  }
}

Write-Host "Pushing $Branch to $RepoUrl ..." -ForegroundColor Cyan
Invoke-Git @("push", "-u", "origin", $Branch)

Write-Host "Done: https://github.com/fake-cmd/the-SHS-bypass/tree/main" -ForegroundColor Green
