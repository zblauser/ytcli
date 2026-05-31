# ytcli
TUI client for yt music<br>

search, browse, and play from your terminal

<p align="center">
  <img src="image.gif" alt="ytcli searching, browsing, and playing" width="82%"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-v0.1-000?style=flat-square&labelColor=500" alt="v0.1"/>
  <img src="https://img.shields.io/badge/license-MIT-000?style=flat-square&labelColor=500" alt="MIT"/>
</p>

zig 0.16, single binary
- libmpv for audio
- shells out to `curl` and
`yt-dlp`<br>
- astats lavfi filter for visualizer via `ffmpeg`

no other dependencies

## version
**-v0.1.-**<br>
- autoplays through result list
- drills into albums
- handful of color themes

## build/install
```sh
zig build                              # → zig-out/bin/ytcli
zig build install --prefix ~/.local    # → ~/.local/bin/ytcli
```
~

```sh
brew install mpv yt-dlp         # macOS
apt install libmpv-dev yt-dlp   # Debian/Ubuntu
```
<br>

> **[ ! ]** currently requires `mpv` and `yt-dlp` particularly on PATH

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

## storage/config
- `$XDG_DATA_HOME/ytcli/history` - query log.
- `$XDG_CONFIG_HOME/ytcli/config` - `key=value` settings.

<br>

> [ ! ] requests written to `/tmp/ytcli_*.json` per call + audio streamed/buffered via mpv; not written to disk.

## visualizer
simple spectrum bars via `astats` lavfi filter<br>
dB to linear/modulated per bar - *not a true per-band FFT*

## contribution
please feel free to contribute, not a guarantee it will be merged<br>

> [ ! ] thank you for your attention

