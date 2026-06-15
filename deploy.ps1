# Spine Clinic App - Web Deploy
# Run me: Right-click → Run with PowerShell, or double-click deploy.bat

Set-Location $PSScriptRoot

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Spine Clinic App - Web Deploy" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. Load .env ──────────────────────────────────────────────
Write-Host "[1/4] Loading .env..." -ForegroundColor Yellow

if (-not (Test-Path ".env")) {
    Write-Host "ERROR: .env file not found in $PSScriptRoot" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$envVars = @{}
Get-Content ".env" | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
        $parts = $line -split "=", 2
        if ($parts.Count -eq 2) {
            $envVars[$parts[0].Trim()] = $parts[1].Trim()
        }
    }
}

$supabaseUrl  = $envVars["SUPABASE_URL"]
$supabaseKey  = $envVars["SUPABASE_ANON_KEY"]

if (-not $supabaseUrl) {
    Write-Host "ERROR: SUPABASE_URL not found in .env" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
if (-not $supabaseKey) {
    Write-Host "ERROR: SUPABASE_ANON_KEY not found in .env" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "  SUPABASE_URL: $supabaseUrl" -ForegroundColor Gray
Write-Host "  ANON_KEY:     $($supabaseKey.Substring(0, [Math]::Min(20, $supabaseKey.Length)))..." -ForegroundColor Gray

# ── 2. Build Flutter web ──────────────────────────────────────
Write-Host ""
Write-Host "[2/4] Building Flutter web (release)..." -ForegroundColor Yellow

$buildArgs = @(
    "build", "web", "--release",
    "--dart-define=SUPABASE_URL=$supabaseUrl",
    "--dart-define=SUPABASE_ANON_KEY=$supabaseKey"
)

# Let stderr flow naturally — Flutter warnings are harmless
& flutter @buildArgs
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Flutter build failed (exit code $LASTEXITCODE)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "  Build complete: build\web\" -ForegroundColor Green

# ── 3. Inject build ID so sw.js changes on every deploy ───────────
# A new byte-for-byte sw.js triggers the browser SW update flow:
# install → skipWaiting → activate → controllerchange → reload.
$buildId = (Get-Date -Format "yyyyMMddHHmmss")
Write-Host "  Build ID: $buildId" -ForegroundColor Gray

$swPath = Join-Path $PSScriptRoot "build\web\sw.js"
if (Test-Path $swPath) {
    $swContent = Get-Content $swPath -Raw
    $swContent = $swContent -replace "BUILD_ID_PLACEHOLDER", $buildId
    Set-Content $swPath $swContent -NoNewline
}

$indexPath = Join-Path $PSScriptRoot "build\web\index.html"
if (Test-Path $indexPath) {
    $indexContent = Get-Content $indexPath -Raw
    $indexContent = $indexContent -replace "BUILD_PLACEHOLDER", $buildId
    Set-Content $indexPath $indexContent -NoNewline
}

# ── 4. Deploy to Firebase ─────────────────────────────────────
Write-Host ""
Write-Host "[4/4] Deploying to Firebase Hosting..." -ForegroundColor Yellow

& firebase deploy --only hosting
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Firebase deploy failed (exit code $LASTEXITCODE)" -ForegroundColor Red
    Write-Host ""
    Write-Host "If not authenticated, run: firebase login --reauth" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# ── Done ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Deploy complete!" -ForegroundColor Green
Write-Host "  https://spine-clinic-app.web.app" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "The SW auto-update flow will reload any open tabs within seconds." -ForegroundColor Green
Read-Host "Press Enter to exit"
