# Starts the title on an NVIDIA card with the Series S settings of trustno1-coder/VIctory-NVIDIA
# (scripts/play-nvidia.ps1 there, measured on an RTX 5070: about 20-22 fps in the prologue), with
# this fork's own fast set (scripts\play.ps1). Their settings for code this fork does not have
# (VICTORY_THIN, CARD_STEPS, SHOW_AFTER, AMBIENT, DYNAMIC_SLOTS ...) are left out, and so is
# VICTORY_BVH_MISS (it takes the bounced light away; the switch is not in this tree).
#   scripts\play-nvidia.ps1 -Exe <path of your own copy's executable>
# -NoSmoothMotion  run target\<build>\victory.exe itself. By default a copy named victory_sm.exe is
#                  started, so a Smooth Motion profile set for that exe in the NVIDIA App applies.
# -SeriesX         the Series X profile instead (slower)
# -Log             where the log goes (default: the console)
# -More            other settings: -More @{VICTORY_RENDER_SCALE='1'}
param(
    [Parameter(Mandatory)][string]$Exe,
    [switch]$NoSmoothMotion,
    [switch]$SeriesX,
    [string]$Log = '',
    [ValidateSet('diag', 'release')][string]$Build = 'diag',
    [hashtable]$More = @{}
)
$settings = @{
    # This fork's fast set (scripts\play.ps1).
    VICTORY_LEVELS_ON_DEMAND = '1'; VICTORY_ASYNC_SUBMIT = '1'; VICTORY_QUEUE2 = '1'
    VICTORY_INDIRECT_WINDOW = '1'; VICTORY_TEXTURE_NO_WAIT = '1'; VICTORY_MERGE_GAP = '64'
    VICTORY_MERGE_RUNS = '4096'; VICTORY_STAGING_POOL = '0'; VICTORY_COPY_PLAIN = '1'
    VICTORY_JOIN_PARTS = '1'; VICTORY_BACK_OWN_VIEW = '1'; VICTORY_INDIRECT_GATHER = '1'
    VICTORY_CARD_REHASH_RUNS = '1'; VICTORY_RELAY = '2'; VICTORY_WIDE_BACK = '1'; VICTORY_JOIN_COPIES = '1'
    VICTORY_INDIRECT_BATCH = '2'
    # From VIctory-NVIDIA's play-nvidia.ps1:
    # wait for new shaders rather than skip their draws (a hitch the first time a place is seen);
    VICTORY_PIPELINE_WAIT_MS = '10000'
    # half render scale with the title's own upscaler (victory-loader hooks.rs);
    VICTORY_RENDER_SCALE = '0.5'; VICTORY_OWN_UPSCALER = '1'
    # memory compares on the card instead of the CPU;
    VICTORY_CARD_BUFFERS_MIN_MB = '1'; VICTORY_CARD_BUFFERS_MB = '1536'
    # Series S presents the interface as a second plane, laid over the game (compose.rs).
    VICTORY_COMPOSE = '1'
}
foreach ($k in $More.Keys) { $settings[$k] = $More[$k] }

$victory = Join-Path $PSScriptRoot "..\target\$Build\victory.exe"
if (-not (Test-Path $victory)) { Write-Host "No $victory. Build it first."; return }
if (-not (Test-Path $Exe)) { Write-Host "No $Exe."; return }
if (-not $NoSmoothMotion) {
    $sm = Join-Path (Split-Path $victory) 'victory_sm.exe'
    if (-not (Test-Path $sm) -or (Get-Item $sm).LastWriteTime -lt (Get-Item $victory).LastWriteTime) {
        Copy-Item $victory $sm -Force
    }
    $victory = $sm
}
$paths = 'VICTORY_CONFIG', 'VICTORY_GAME_DIR', 'VICTORY_CACHE_DIR', 'VICTORY_DATA_DIR'
Get-ChildItem Env:VICTORY_* | Where-Object { $_.Name -notin $paths } | ForEach-Object { Remove-Item "Env:$($_.Name)" }
foreach ($k in $settings.Keys) { Set-Item "Env:$k" $settings[$k] }
$Exe = (Resolve-Path $Exe).Path
$runArgs = @('run', $Exe, '--execute')
if (-not $SeriesX) { $runArgs += @('--console', 'series-s') }
Push-Location (Join-Path $PSScriptRoot '..')   # victory.toml is looked for here
try {
    if ($Log) { & $victory @runArgs *> $Log } else { & $victory @runArgs }
} finally { Pop-Location }
