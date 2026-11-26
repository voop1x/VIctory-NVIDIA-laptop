# VIctory: an NVIDIA build on top of fxceless

A compatibility layer that runs an Xbox Series title natively on Windows from
files the user supplies. This build is a fork of
[fxceless/victory-fork](https://github.com/fxceless/victory-fork) with tested
fixes taken over one at a time from
[avatarmanz/VIctory-7900XTX](https://github.com/avatarmanz/VIctory-7900XTX) and
[trustno1-coder/VIctory-NVIDIA](https://github.com/trustno1-coder/VIctory-NVIDIA).
The goal is speed on an NVIDIA card without losing the lighting.

**This repository contains no game files, code or assets.** You need your own
copy of the game. It is not affiliated with or endorsed by the game's developer
or publisher.

## What this build is

- **Base:** fxceless/victory-fork at commit `9c184b3`, the version before its
  update of 2026-11-25 (evening). That later update (19 commits) was taken
  over and tested, but **the lighting was gone with it**, so it is kept on the
  branch `with-upstream-nov25` and is not part of this build.
- **On top of the base:** fixes from VIctory-7900XTX and VIctory-NVIDIA, only
  those tested on this machine that do not break the picture (listed below).
- **Branch:** `integrate-7900xtx`. Every fix is a commit of its own that names
  its source; any of them can be undone with `git revert`.

## Where it stands (2026-11-26)

Tested on one machine: a laptop with an RTX 5070 Ti Laptop GPU (12 GB),
Windows 11, a 2560x1600 screen, the `diag` build, the title's 1.0.2.1 build.

| Launch | Frame in the world | The title's work on the card |
|---|---|---|
| fxceless, default settings | 320-440 ms (2-3 fps) | - |
| `scripts\play.ps1` (fxceless' fast set + indirect batches) | about 190-240 ms (4-5 fps) | about 170 ms |
| `scripts\play-nvidia.ps1` (Series S, half render scale) | **about 110-150 ms (7-9 fps)** | **about 80 ms** |

The lighting is as in fxceless in both (fxceless has no ray-traced bounce
light, and never had). Longest session: about 15 minutes with no crash and no
device loss.

## How to run it

You need Windows 10/11 x64, a CPU with AVX2, a Direct3D 12 GPU with shader
model 6.6 and mesh shaders, Rust (the toolchain is pinned in
`rust-toolchain.toml`), the MSVC build tools, and your own copy of the title.

```powershell
copy victory.example.toml victory.toml      # set game_dir (outside this folder)
cargo build --locked --profile diag -p victory --features diagnostics
```

**Recommended on NVIDIA** (the fastest):

```powershell
scripts\play-nvidia.ps1 -Exe <path of game_scarlett_master.exe>
```

Options of `play-nvidia.ps1`:

- `-NoSmoothMotion`: run `victory.exe` itself. By default a copy named
  `victory_sm.exe` is started; with Smooth Motion turned on for it in the
  NVIDIA App the driver inserts generated frames (controls still respond at
  the real frame rate).
- `-SeriesX`: the Series X profile instead of Series S (slower, full quality).
- `-Log <file>`: write the log to a file.
- `-More @{...}`: more switches, e.g. `-More @{VICTORY_RENDER_SCALE='1'}` for
  the full render scale.

**Without the title patches** (Series X profile, full resolution):

```powershell
scripts\play.ps1 -Exe <path of game_scarlett_master.exe>
```

Options of `play.ps1`: `-Safe` (fxceless' defaults, to compare),
`-Console series-x|series-s`, `-Display WxH` (the display mode reported to the
title; 3840x2160 by default), `-Log`, `-More`.

## What is changed against fxceless

### From VIctory-7900XTX

| Commit | What | On |
|---|---|---|
| `dba0299` | DXIL's `Log` is already base 2: cube texture levels came out 1.44 times too high, reflections blurred (DexNom 921d8d3b). With a test. | always |
| `442765d` | Indirect records clamped in batches (`VICTORY_INDIRECT_BATCH`): about 2,300 clamp passes a frame, each between two full waits of the card, become a few batches; frames about 13 % shorter. The batch shader uses fxceless' bounds; a WARP test checks it against the single clamp. Off after the first driver error. | both scripts (`=2`) |
| `29586c0` | The card's clocks kept up between submissions (`VICTORY_CARD_AWAKE`). No gain on this card. | off |

### From VIctory-NVIDIA

| Commit | What | On |
|---|---|---|
| `8dc0dd9` | Title patches (victory-perf, from ZigZagBoi1/ScarlettPort): render scale (`VICTORY_RENDER_SCALE`), the title's own upscaler instead of FSR (`VICTORY_OWN_UPSCALER`), the watchdog disarmed (`VICTORY_NO_WATCHDOG`). Each patch checks the 1.0.2.1 build's hash and the exact bytes it replaces, and does nothing otherwise. | `play-nvidia.ps1` (0.5 and the upscaler) |
| `6140743` | Series S interface plane (`VICTORY_COMPOSE`, a port of fxceless pull request 1189 by Tissma95): without it menus, loading screens and subtitles are black on Series S. | `play-nvidia.ps1` |
| `8a529ef` | The same render targets are not set again (after ZJOU acf478b8). `VICTORY_BIND_CACHE=0` for the old way. | always |
| `8dbd6f3` | A pipeline a list binds again is not kept and named again (from Belobug 92d353f8, romainhedouin). | always |
| `2dca8fb`, `d2dbe36` | `scripts\play-nvidia.ps1`: the settings of VIctory-NVIDIA that this build has. | - |

`play-nvidia.ps1` also turns on fxceless' own switches: memory compares on the
card (`VICTORY_CARD_BUFFERS_MIN_MB=1`, `VICTORY_CARD_BUFFERS_MB=1536`) and
waiting for new shaders instead of skipping their draws
(`VICTORY_PIPELINE_WAIT_MS=10000`).

## Tried and not taken

- **fxceless' update of 2026-11-25 (19 commits):** the lighting was gone with
  it. On the branch `with-upstream-nov25`.
- **`VICTORY_BVH_MISS` (VIctory-NVIDIA):** saves time but takes the bounced
  light away; dim places get darker. On the branch `with-nvidia-fixes`.
- **Normalized buffer codes and pixel shader helper lanes (VIctory-7900XTX):**
  on NVIDIA they gave a black screen and a much lower frame rate in the
  prologue; reverted (`247c09d`, `31612f5`).
- **Dispatches of more than 65,535 groups (VIctory-7900XTX):** AMD only.
- **`SHOW_AFTER`, `THIN`, `CARD_STEPS`, the rewritten `watch.rs` and
  `descriptor/host.rs` (VIctory-7900XTX):** whole subsystems, not single
  fixes; fxceless does not have them.
- **More dynamic descriptor slots (VIctory-NVIDIA):** they do not run out here
  (0 refused in a run); they were needed with `THIN`.
- **Belobug's `c96525d` and `b32fb99`:** they build on VIctory-7900XTX code.
- **XCL:** GPL-2.0-only, which does not combine with this project's
  GPL-3.0-or-later; none of its code is here.

## Known problems

- With `play-nvidia.ps1` (Series S, half render scale) some textures are
  missing or come late; the cause is not found yet. To narrow it down:
  `-SeriesX` (the profile) or `-More @{VICTORY_RENDER_SCALE='1'}` (the scale).
- In the world the card is still the limit: a few of the title's compute
  programs take 17-18 ms a dispatch, and the console's wave64 programs run on
  NVIDIA as two 32-lane waves that exchange through shared memory.
- The first minutes after the shader translator changes, shaders are
  translated again and the title stutters more than usual.
- Tests: `cargo test -p victory-gpu --features diagnostics` and
  `cargo test -p victory-shader` pass; some WARP tests of `victory-gpu` fail
  now and then when run in parallel, in fxceless too.

## Branches

- `integrate-7900xtx`: this build.
- `with-upstream-nov25`: the same plus fxceless' update of 2026-11-25 (no
  lighting).
- `with-nvidia-fixes`: an earlier state with `VICTORY_BVH_MISS`.

## Credits

This is a tree of other people's work with a little on top.

- [Marvisak/VIctory](https://github.com/Marvisak/VIctory) and its contributors:
  the loader, the runtime services, the Direct3D 12 back end and the shader
  recompiler.
- [fxceless/victory-fork](https://github.com/fxceless/victory-fork) and the
  people whose pull requests it carries: the base of this build; Tissma95 for
  the Series S interface plane.
- [avatarmanz/VIctory-7900XTX](https://github.com/avatarmanz/VIctory-7900XTX):
  indirect batches, keeping the card awake, the cube level test.
- [trustno1-coder/VIctory-NVIDIA](https://github.com/trustno1-coder/VIctory-NVIDIA):
  the render scale and upscaler patches (via victory-perf and
  ZigZagBoi1/ScarlettPort) and the NVIDIA launcher.
- [DexNom/VIctory](https://github.com/DexNom/VIctory),
  [Belobug/VIctory-Belobug-AMD](https://github.com/Belobug/VIctory-Belobug-AMD)
  (romainhedouin) and
  [FQY55kai/ZJOU-VICTORY](https://github.com/FQY55kai/ZJOU-VICTORY), through
  the forks above.
- This build's changes were made with [Claude Code](https://claude.com/claude-code).

fxceless' own README, with the commands, the debugging switches and its
history: [docs/README-fxceless.md](docs/README-fxceless.md).

## License

GPL-3.0-or-later, as VIctory. See [LICENSE](LICENSE); the one file that is not
covered is named in [docs/asset-policy.md](docs/asset-policy.md).
