param(
  [string]$Message = "Update: apply local changes",
  [string]$Remote = "origin",
  [string]$Branch = "main"
)

function ExitWithError($msg) {
  Write-Error $msg
  exit 1
}

# Ensure we're inside a git repo
try {
  $inside = git rev-parse --is-inside-work-tree 2>$null
} catch {
  ExitWithError "This folder is not a git repository. Run this script from the repository root."
}

Write-Host "Staging changes..."
git add -A

$status = git status --porcelain
if ([string]::IsNullOrWhiteSpace($status)) {
  Write-Host "No changes to commit. Exiting."
  exit 0
}

try {
  Write-Host "Committing with message: $Message"
  git commit -m $Message
} catch {
  ExitWithError "Commit failed: $_"
}

try {
  Write-Host "Pushing to $Remote/$Branch..."
  git push $Remote $Branch
  if ($LASTEXITCODE -ne 0) {
    ExitWithError "Push failed with exit code $LASTEXITCODE"
  }
  Write-Host "Push complete."
} catch {
  ExitWithError "Push error: $_"
}
