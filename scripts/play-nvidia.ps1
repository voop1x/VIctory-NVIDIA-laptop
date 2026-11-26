# Starts the title on an NVIDIA card with the Series S settings of trustno1-coder/VIctory-NVIDIA
# (scripts/play-nvidia.ps1 there, measured on an RTX 5070: about 20-22 fps in the prologue), with
# this fork's own fast set (scripts\play.ps1). Their settings for code this fork does not have
# (VICTORY_THIN, CARD_STEPS, SHOW_AFTER, AMBIENT, DYNAMIC_SLOTS ...) are left out, and so is
# VICTORY_BVH_MISS (it takes the bounced light away; the switch is not in this tree).
#   scripts\play-nvidia.ps1 -Exe <path of your own copy's executable>
# -NoSmoothMotion  run target\<build>\victory.exe itself. By default a copy named victory_sm.exe is
#                  started, so a Smooth Motion profile set for that exe in the NVIDIA App applies.
# Default: the Series S profile at half render scale (0.5) with the title's own upscaler, the
#                  fastest set (textures can be missing or late there).
# -SeriesX         full quality instead: the Series X profile at the title's own render resolution
#                  (about half the frame rate).
# -SeriesS         accepted for older command lines; Series S at 0.5 is the default
# -Log             where the log goes (default: the console)
# -More            other settings: -More @{VICTORY_RENDER_SCALE='0.75'}
param(
    [Parameter(Mandatory)][string]$Exe,
    [switch]$NoSmoothMotion,
    [switch]$SeriesS,
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
    # do not wait for new pipelines: draws without one are skipped until it is made in the
    # background (was '10000', which on a fresh shader cache blocked frames for seconds and Windows
    # closed the window as not responding). -More @{VICTORY_PIPELINE_WAIT_MS='10000'} for the old way.
    VICTORY_PIPELINE_WAIT_MS = '0'
    # memory compares on the card instead of the CPU;
    VICTORY_CARD_BUFFERS_MIN_MB = '1'; VICTORY_CARD_BUFFERS_MB = '1536'
    # Series S presents the interface as a second plane, laid over the game (compose.rs).
    VICTORY_COMPOSE = '1'
    # A thread remembers what its asks for a buffer's host copy found (shadow.rs; fxceless
    # 32be36d, measured there about 14 ms a frame).
    VICTORY_LOOKUP_CACHE = '1'
    # Textures picked by index are uploaded by a thread of their own (heap_worker.rs; fxceless
    # d4a528b, fork pull request #1007: 6.2-6.7 -> 8.6-9.5 fps there). Needs late wait, which
    # VICTORY_RELAY above turns on.
    VICTORY_HEAP_WORKER = '1'
    # Flights get more room before they are settled (host.rs; fxceless 06702fe: the preparing
    # thread waits for the card 4.6 ms a frame instead of 17.7 there).
    VICTORY_SETTLE_ROOM = '1'
    # A submission's texture checks run side by side on the helper threads (host.rs; fxceless
    # ceb9e1f: -8.7 / -9.4 ms of the preparing thread's work a frame there).
    VICTORY_PARALLEL_REFRESH = '1'
    # The ocean's height and displacement maps go back to title memory: the title's CPU reads
    # them (boats float on them). Without it the water is wrong and boats sink (texback.rs).
    VICTORY_TEXTURE_BACK = '1'
    # Crash tracing cheap enough to leave on: the faulting address of a removed device.
    VICTORY_D3D12_DRED = 'faults'
    # The language the title is told (XPackageGetUserLocale): Russian text and subtitles.
    VICTORY_LOCALE = 'ru-RU'
}
$SeriesS = -not $SeriesX
if ($SeriesS) {
    # half render scale with the title's own upscaler (victory-loader hooks.rs).
    $settings.VICTORY_RENDER_SCALE = '0.5'; $settings.VICTORY_OWN_UPSCALER = '1'
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
if ($SeriesS) { $runArgs += @('--console', 'series-s') }   # Series X is victory's default
Push-Location (Join-Path $PSScriptRoot '..')   # victory.toml is looked for here
try {
    if ($Log) { & $victory @runArgs *> $Log } else { & $victory @runArgs }
} finally { Pop-Location }
