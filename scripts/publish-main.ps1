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
  param([string[]]$GitArgs)

  & $script:GitExe @GitArgs
  if ($LASTEXITCODE -ne 0) {
    throw "git $($GitArgs -join ' ') failed with exit code $LASTEXITCODE"
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
  Write-Host "Not inside a git repo. Preparing clone path: $CloneDir" -ForegroundColor Yellow
  if (!(Test-Path $CloneDir)) {
    Invoke-Git -GitArgs @("clone", $RepoUrl, $CloneDir)
    Set-Location $CloneDir
  } else {
    Set-Location $CloneDir
    try {
      & $script:GitExe rev-parse --is-inside-work-tree *> $null
      if ($LASTEXITCODE -ne 0) {
        throw "not-a-repo"
      }
    } catch {
      throw "CloneDir exists but is not a git repository: $CloneDir"
    }
  }
} else {
  Write-Host "Detected existing git repository: $(Get-Location)" -ForegroundColor Cyan
}

$originExists = $false
try {
  & $script:GitExe remote get-url origin *> $null
  if ($LASTEXITCODE -eq 0) { $originExists = $true }
} catch {
  $originExists = $false
}

if ($originExists) {
  Invoke-Git -GitArgs @("remote", "set-url", "origin", $RepoUrl)
} else {
  Invoke-Git -GitArgs @("remote", "add", "origin", $RepoUrl)
}

Invoke-Git -GitArgs @("fetch", "origin")
Invoke-Git -GitArgs @("checkout", "-B", $Branch)

$changes = & $script:GitExe status --porcelain
if ($changes) {
  throw "Working tree has uncommitted changes. Commit/stash first, then run again."
}

Write-Host "Pushing $Branch to $RepoUrl ..." -ForegroundColor Cyan
Invoke-Git -GitArgs @("push", "-u", "origin", $Branch)

Write-Host "Done: https://github.com/fake-cmd/the-SHS-bypass/tree/main" -ForegroundColor Green
