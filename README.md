# ytcli
TUI client for yt music<br>
search, browse, and play from your terminal

<p align="center">
  <img src="assets/ytcli.gif" alt="ytcli searching, browsing, and playing" width="82%"/>
</p>

<p align="center">
  <img src="https://img.shields.io/github/v/tag/zblauser/ytcli?sort=semver&style=flat-square&labelColor=500&color=000&label=version" alt="version"/>
  <img src="https://img.shields.io/badge/license-MIT-000?style=flat-square&labelColor=500" alt="MIT"/>
</p>

zig 0.16, single binary
- `libmpv` for audio
- shells out to `curl` and
`yt-dlp`<br>
- astats lavfi filter for visualizer via `ffmpeg`

## version
<b>v0.1.3</b>
+ selecting a track stops audio immediately + shows `connecting to YouTube…` in the now-playing footer
+ fix album view mislabeling tracks with a related artist (reads album header, not first channel link)
+ fix freeBSD build (drop `<time.h>` + `<sys/stat.h>` cimports that drag in `<sys/time.h>`; use `extern`/`std.c`)
+ release CI fails fast on stalled runners (`timeout-minutes`)
<details>
<summary>previous</summary><br>

<b>v0.1.2</b><br>
+ failures log to `~/.local/share/ytcli/log` (timestamp + cause)<br>
+ ctrl+c restores cleanly to terminal in all cases<br>
+ play video ids beginning with `-` (yt-dlp `--` arg fix)<br>
+ fix freeBSD build (terminal size via std, not `<sys/ioctl.h>`)<br>
+ readme fix: `brew install mpv` already pulls in `yt-dlp`, `libmpv-dev` however does not

<b>v0.1.1</b><br>
+ github actions for release builds<br>
+ prebuilt binaries: macOS, linux, freeBSD<br>
+ hardened temp writes (mkstemp, 0600)

<b>v0.1</b><br>
+ autoplays through result list
+ drills into albums
+ handful of color themes
</details>

## build/install
```sh
zig build                              # → zig-out/bin/ytcli
zig build install --prefix ~/.local    # → ~/.local/bin/ytcli
```
## dependencies

```sh
install ex.
brew install mpv ffmpeg                # macOS (mpv pulls in yt-dlp)
apt install libmpv-dev yt-dlp ffmpeg   # Debian/Ubuntu
```
<br>

> **[ ! ]** currently requires `mpv`, `ffmpeg` and `yt-dlp` particularly on PATH

## releases

macOS, Linux, and FreeBSD binaries are attached to each [release](../../releases). windows: run under WSL (no native build currently).

## run
```sh
ytcli               # TUI
ytcli <query>       # play first hit
ytcli -s <query>    # search, print results
ytcli history       # past queries
ytcli --theme cyan  # red (default) | cyan | mono | dracula | nord | gruvbox
ytcli --themes      # list themes
ytcli -h | -v
```

## commands

made an effort to use commands that felt intuitive

<details>
<summary>view</summary><br>

**typing:**<br>
- text to query `↑/↓`
- pick suggestion `tab`/`→`
- accept completion `⏎` search
- `esc` clear
- `Ctrl+T` cycle filter (all/songs/videos/albums/artists)

**results:**
 - `j/k` or `↑/↓` move
 - `g/G` top/end
 - `Ctrl+F/B` page
 -  `h`/`esc` back

**playback/anytime:**
- `Ctrl+P`/`space` pause
- `Ctrl+N` next
- `Ctrl+S` stop
- `[`/`]` seek ±10s
- `{`/`}` ±60s
- `-`/`=` volume ±5
- `Ctrl+Y` theme
</details>

## storage/config
- `$XDG_DATA_HOME/ytcli/history` - query log (falls back to `~/.local/share/ytcli/history`).
- `$XDG_DATA_HOME/ytcli/log` - timestamped failures (search/album/stream) with the underlying error and any `curl`/`yt-dlp` stderr. check here first when something says `(see log)`.
- `$XDG_CONFIG_HOME/ytcli/config` - `key=value` settings.

history is just newline-delimited text - `grep`/`cat` it, or seed it so the TUI autocompletes your favorites from the first keystroke:
```sh
ex.
printf '%s\n' "elephant gym" "autechre" "john zorn" >> ~/.local/share/ytcli/history
grep -i jazz ~/.local/share/ytcli/history
```
> [ ! ] loads newest-first and dedups, so re-seeding or reordering is harmless.

`ytcli -s <query>` prints `title — artist [video_id]`, one per line; pipe it anywhere. `YTCLI_THEME` sets the theme without a flag.

> [ ! ] requests written to `/tmp/ytcli_body*` (mkstemp, 0600, unlinked after) per call + audio streamed/buffered via mpv; not written to disk.

## visualizer
simple spectrum bars via `astats` lavfi filter<br>
dB to linear/modulated per bar - *not a true per-band FFT*

## contribution
please feel free to contribute, not a guarantee it will be merged<br>

> [ ! ] thank you for your attention

