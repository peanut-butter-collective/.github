# install.ps1 — Peanut Butter Collective public installer (stage 0). Human-run.
#
#   irm https://raw.githubusercontent.com/peanut-butter-collective/.github/main/install.ps1 | iex
#
# Gets a fresh Windows machine from nothing to a working PBC workspace: installs
# git + the GitHub CLI (via winget), signs you in, then hands off to the private
# workspace installer in pbc-manifest. You must be a member of the
# peanut-butter-collective GitHub org, and Developer Mode must be enabled
# (Settings > System > For developers) so the workspace can be set up without
# administrator rights.
$ErrorActionPreference = 'Stop'

function Info($m) { Write-Host "[pbc] $m" -ForegroundColor Cyan }
function Die($m)  { Write-Host "[error] $m" -ForegroundColor Red; exit 1 }
function Have($n) { $null -ne (Get-Command $n -ErrorAction SilentlyContinue) }

if (-not (Have winget)) {
    Die "winget not found. Install 'App Installer' from the Microsoft Store: https://aka.ms/getwinget"
}

if (Have git) { Info "git already installed" } else {
    Info "Installing git..."
    winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
}
if (Have gh) { Info "gh already installed" } else {
    Info "Installing the GitHub CLI (gh)..."
    winget install --id GitHub.cli -e --accept-source-agreements --accept-package-agreements
}

# Refresh PATH so freshly-installed tools resolve in this session.
$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' +
            [System.Environment]::GetEnvironmentVariable('Path','User')

# Authenticate.
& gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
    Info "Signing you in to GitHub (you must be a peanut-butter-collective member)..."
    gh auth login
}

# Hand off to the private workspace installer.
Info "Fetching and running the PBC workspace installer..."
gh api repos/peanut-butter-collective/pbc-manifest/contents/install.ps1 -H "Accept: application/vnd.github.raw" | iex
