#!/usr/bin/env pwsh
# =====================================================
# SUPABASE DEPLOYMENT SCRIPT - Windows PowerShell
# =====================================================
# Complete deployment automation for Windows

Write-Host "Deploying Supabase Backend..." -ForegroundColor Cyan

# Check if Supabase CLI is installed
Write-Host "`nChecking prerequisites..." -ForegroundColor Yellow
if (!(Get-Command supabase -ErrorAction SilentlyContinue)) {
    Write-Host "Supabase CLI not found. Installing..." -ForegroundColor Red
    npm install -g supabase
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install Supabase CLI" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Supabase CLI found" -ForegroundColor Green

# Login to Supabase
Write-Host "`nLogging in to Supabase..." -ForegroundColor Yellow
supabase login
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to login" -ForegroundColor Red
    exit 1
}

# Link to project (if not already linked)
Write-Host "`nLinking to Supabase project..." -ForegroundColor Yellow
if (!(Test-Path ".\.supabase\config.toml")) {
    $projectRef = Read-Host "Enter your Supabase project reference ID"
    supabase link --project-ref $projectRef
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to link project" -ForegroundColor Red
        exit 1
    }
}

# Deploy database schema
Write-Host "`nDeploying database schema..." -ForegroundColor Yellow
$confirmation = Read-Host "This will reset your database. Continue? (yes/no)"
if ($confirmation -eq "yes") {
    supabase db push
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to deploy schema" -ForegroundColor Red
        exit 1
    }
    Write-Host "Database schema deployed" -ForegroundColor Green
} else {
    Write-Host "Skipping schema deployment" -ForegroundColor Yellow
}

# Set environment secrets
Write-Host "`nSetting secrets..." -ForegroundColor Yellow
$geminiKey = Read-Host "Enter your Gemini API key" -AsSecureString
$geminiKeyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($geminiKey)
)
supabase secrets set "GEMINI_API_KEY=$geminiKeyPlain"
Write-Host "Secrets configured" -ForegroundColor Green

# Deploy Edge Functions
Write-Host "`nDeploying Edge Functions..." -ForegroundColor Yellow

$functions = @(
    "generate-roadmap",
    "analyze-resume",
    "award-xp",
    "unlock-project",
    "complete-project",
    "leaderboard",
    "daily-rewards"
)

foreach ($func in $functions) {
    Write-Host "  Deploying $func..." -ForegroundColor Cyan
    supabase functions deploy $func
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  $func deployed" -ForegroundColor Green
    } else {
        Write-Host "  Failed to deploy $func" -ForegroundColor Red
    }
}

# Enable Realtime
Write-Host "`nEnabling Realtime..." -ForegroundColor Yellow
Write-Host "  Go to Supabase Dashboard > Database > Replication" -ForegroundColor Cyan
Write-Host "  Enable realtime for these tables:" -ForegroundColor Cyan
Write-Host "    - users" -ForegroundColor White
Write-Host "    - roadmap_nodes" -ForegroundColor White
Write-Host "    - achievements" -ForegroundColor White
Write-Host "    - notifications" -ForegroundColor White
Write-Host "    - leaderboard_cache" -ForegroundColor White

# Create Storage Buckets
Write-Host "`nCreating Storage Buckets..." -ForegroundColor Yellow
Write-Host "  Go to Supabase Dashboard > Storage" -ForegroundColor Cyan
Write-Host "  Create these buckets:" -ForegroundColor Cyan
Write-Host "    - career-resumes (public read, authenticated write)" -ForegroundColor White
Write-Host "    - user-avatars (public read)" -ForegroundColor White
Write-Host "    - project-thumbnails (public read)" -ForegroundColor White

# Generate TypeScript types for Flutter
Write-Host "`nGenerating TypeScript types..." -ForegroundColor Yellow
supabase gen types typescript --local > lib\database.types.ts
Write-Host "Types generated" -ForegroundColor Green

Write-Host "`nDeployment Complete!" -ForegroundColor Green
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "  1. Enable Realtime in Supabase Dashboard" -ForegroundColor White
Write-Host "  2. Create Storage Buckets" -ForegroundColor White
Write-Host "  3. Configure OAuth providers" -ForegroundColor White
Write-Host "  4. Update Flutter app with Supabase URL and keys" -ForegroundColor White
Write-Host "  5. Test API endpoints" -ForegroundColor White

Write-Host "`nUseful Links:" -ForegroundColor Yellow
Write-Host "  Dashboard: https://supabase.com/dashboard" -ForegroundColor Cyan
Write-Host "  Docs: https://supabase.com/docs" -ForegroundColor Cyan
