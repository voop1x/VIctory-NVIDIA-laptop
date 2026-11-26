# Starts the title with the fast switch set (after VIctory-7900XTX scripts\play.ps1,
# with the switches this fork has; fxceless README "run 253" set plus the shared ones).
#   scripts\play.ps1 -Exe <path of your own copy's executable>
# -Safe   the plain defaults (every switch below left out), to compare or when something is wrong
# -Log    where the log goes (default: none, the console)
# -More   other settings: -More @{VICTORY_FPS_COUNTER='0'}
# -Console series-x (default) or series-s: the console model the title sees (it picks its own render settings)
# -Display WxH: the display mode reported to the title (fxceless VICTORY_DISPLAY_MODE; unset: 3840x2160)
param(
    [Parameter(Mandatory)][string]$Exe,
    [switch]$Safe,
    [string]$Log = '',
    [ValidateSet('diag', 'release')][string]$Build = 'diag',
    [ValidateSet('series-x', 'series-s')][string]$Console = 'series-x',
    [string]$Display = '',
    [hashtable]$More = @{}
)
$settings = @{}
if (-not $Safe) {
    $settings = @{
        # fxceless README, run 253
        VICTORY_LEVELS_ON_DEMAND = '1'; VICTORY_ASYNC_SUBMIT = '1'; VICTORY_QUEUE2 = '1'
        VICTORY_INDIRECT_WINDOW = '1'; VICTORY_TEXTURE_NO_WAIT = '1'; VICTORY_MERGE_GAP = '64'
        VICTORY_MERGE_RUNS = '4096'; VICTORY_STAGING_POOL = '0'; VICTORY_COPY_PLAIN = '1'
        VICTORY_JOIN_PARTS = '1'; VICTORY_BACK_OWN_VIEW = '1'; VICTORY_INDIRECT_GATHER = '1'
        VICTORY_CARD_REHASH_RUNS = '1'
        # also in VIctory-7900XTX's set
        VICTORY_RELAY = '2'; VICTORY_WIDE_BACK = '1'; VICTORY_JOIN_COPIES = '1'
        # ported from VIctory-7900XTX: about 13 % shorter frames in the world (run-batch, by turns)
        VICTORY_INDIRECT_BATCH = '2'
    }
}
if ($Display) { $settings.VICTORY_DISPLAY_MODE = $Display }
foreach ($k in $More.Keys) { $settings[$k] = $More[$k] }

$victory = Join-Path $PSScriptRoot "..\target\$Build\victory.exe"
if (-not (Test-Path $victory)) { Write-Host "No $victory. Build it first."; return }
if (-not (Test-Path $Exe)) { Write-Host "No $Exe."; return }
$paths = 'VICTORY_CONFIG', 'VICTORY_GAME_DIR', 'VICTORY_CACHE_DIR', 'VICTORY_DATA_DIR'
Get-ChildItem Env:VICTORY_* | Where-Object { $_.Name -notin $paths } | ForEach-Object { Remove-Item "Env:$($_.Name)" }
foreach ($k in $settings.Keys) { Set-Item "Env:$k" $settings[$k] }
$Exe = (Resolve-Path $Exe).Path
Push-Location (Join-Path $PSScriptRoot '..')   # victory.toml is looked for here
try {
    if ($Log) { & $victory run $Exe --execute --console $Console *> $Log } else { & $victory run $Exe --execute --console $Console }
} finally { Pop-Location }
