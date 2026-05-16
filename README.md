# feline

A small, fast set of command-line tools that make your Mac experience simpler.
Each command is a separate, self-contained script — bundled together behind a
single `feline` entry point so they share a clean, consistent feel.

```
feline download   download files, images, videos from any URL
feline convert    convert files between formats (images, video, audio, docs)
feline clean      free up disk space from caches and junk
feline context    show detailed info and metadata for any file or directory
feline snap       system snapshot with battery / memory / performance tips
feline search     fast file and app search (powered by Spotlight)
feline scrape     pull text, links, or images from any webpage
feline lock       block distracting sites and apps for a set time
```

## Why feline?

- **Small** — the dispatcher is a 33KB C binary. Tools are short scripts.
- **Fast** — no slow startup, no JavaScript, no Electron.
- **Native** — wraps macOS tools already on your system (`mdfind`, `mdls`,
  `osascript`, `pmset`, `launchctl`, etc.) instead of reinventing them.
- **Modular** — every command is a separate file. Use whatever you want,
  ignore the rest.

## Install

```bash
git clone <repo> feline
cd feline
./install.sh
```

The installer will:
1. Build the C dispatcher
2. Install everything to `/usr/local/bin`
3. Check which optional dependencies (ffmpeg, yt-dlp, ImageMagick, pandoc)
   you have, and offer to install any missing ones via Homebrew

You may be asked for `sudo` once if `/usr/local/bin` isn't writable.

## Uninstall

```bash
./uninstall.sh
```

Removes every binary, every LaunchAgent feline ever created, and all stored
data under `~/.feline/`. Nothing is left behind.

## Commands

### `feline download <url> [filetype]`

Downloads any file from the internet — direct URLs go through `curl`, video
sites go through `yt-dlp`. Auto-names the output, avoids overwriting.

```bash
feline download https://example.com/photo.png
feline download https://youtube.com/watch?v=xyz mp4   # video
feline download https://youtube.com/watch?v=xyz mp3   # extract audio
```

### `feline convert <file> <format>`

Converts files between formats. Routes to the right tool automatically:

| Type           | Tool used    |
| -------------- | ------------ |
| Images         | ImageMagick  |
| Audio / Video  | ffmpeg       |
| Documents      | pandoc       |
| Video → GIF    | ffmpeg (2-pass palette for quality) |

```bash
feline convert photo.png jpg
feline convert clip.mov mp4
feline convert song.wav mp3
feline convert notes.md pdf
```

### `feline clean [targets...] [--dir <path>] [--dry-run]`

Shows what each cache holds, asks once, then clears whatever you confirm.
Supports an **interactive select mode** — type `s` instead of `y` to pick
individual targets.

| Target | What it clears |
| ------ | -------------- |
| `caches`, `logs`, `trash`        | macOS user data |
| `brew`, `npm`, `pip`, `yarn`, `gem` | Package manager caches |
| `xcode`, `ios-sim`               | Xcode derived data + unused simulators |
| `browsers`                       | Safari, Chrome, Brave, Firefox caches |
| `ds-store`, `node-modules`, `pycache` | Search-based (use `--dir`) |

```bash
feline clean                      # interactive
feline clean --dry-run            # preview only
feline clean trash browsers
feline clean node-modules --dir ~/Projects
```

### `feline context <file-or-directory>`

Shows everything useful about a file or folder:

- Path, size, type, permissions, owner, timestamps
- Last git commit and status (if in a repo)
- References to the file elsewhere in the same folder

It pulls rich metadata from macOS Spotlight's `mdls` database:

- Images: dimensions, color profile, camera, GPS coordinates
- Audio: title, artist, album, bitrate, sample rate
- Video: resolution, frame rate, codecs, duration
- Documents: title, authors, page count
- Code/text: line / word / character count plus first-lines preview

For directories: total size, breakdown by file type, largest files, recent
changes, and git branch / status.

### `feline snap`

Live system snapshot with actionable recommendations:

- Battery: charge bar, health, cycle count, condition
- Performance: CPU usage, memory usage, memory pressure, uptime
- Top CPU and memory consumers (color-coded by severity)
- Smart recommendations — knows that Slack and Chrome are memory hogs,
  warns about low battery / health, etc.

### `feline search <query> [options]`

Instant Spotlight-powered file and app search.

```bash
feline search "budget report"
feline search xcode --apps              # search /Applications only
feline search "TODO" --content          # full-text search
feline search notes --type md           # filter by extension
feline search panic --dir ~/Projects    # limit to one directory
```

### `feline scrape <url> [options]`

Pulls content out of any webpage using only Python's stdlib — no extra deps.

```bash
feline scrape https://example.com               # readable text
feline scrape https://news.ycombinator.com --links
feline scrape https://example.com --images
feline scrape https://example.com --output page.txt
```

SSL is verified by default. If you hit a cert error on macOS, run
`/Applications/Python\ 3.*/Install\ Certificates.command` to install the
system trust store. `--insecure` exists but should only be used on sites
you trust.

### `feline lock <target> <duration> [--password]`

Block distracting sites and apps for a set time.

- **Apps** — a small background watchdog hides them whenever you try to
  open them, with a notification telling you when they unlock
- **Sites** — entries are added to `/etc/hosts` and blocked browser-wide
  (requires `sudo` once when locking and once when unlocking)
- **Smart detection** — if you pass `Twitter`, it figures out whether
  that's an installed app, a website, or both
- **Password protection** — `--password` requires a password to unlock
  early. A one-time recovery key is shown at lock time for emergencies

```bash
feline lock Slack 2h
feline lock reddit.com 30m --password
feline lock --list
feline lock --unlock Slack
feline lock --unlock reddit.com --emergency    # use recovery key
```

Duration: `30m`, `2h`, `1h30m`. Locks auto-clean on expiry.

## Optional dependencies

These are needed only for certain commands. The installer offers to set
them up via Homebrew the first time you run it.

| Tool        | Used by         | Install                   |
| ----------- | --------------- | ------------------------- |
| ffmpeg      | convert         | `brew install ffmpeg`     |
| yt-dlp      | download (video)| `brew install yt-dlp`     |
| ImageMagick | convert (images)| `brew install imagemagick`|
| pandoc      | convert (docs)  | `brew install pandoc`     |

Everything else (`curl`, `mdfind`, `mdls`, `osascript`, `launchctl`,
`pmset`, `vm_stat`, Python 3) ships with macOS.

## Where feline stores data

| Location | What it holds |
| -------- | ------------- |
| `/usr/local/bin/feline*`              | binaries |
| `~/.feline/locks/`                    | active lock state |
| `~/.feline/lock-watchdog.sh`          | app-lock watchdog script |
| `~/Library/LaunchAgents/com.feline.*` | scheduled lock-expiry agents |

`./uninstall.sh` removes all of it.

## Safety notes

- `feline clean` always shows a preview and requires explicit confirmation
  before deleting anything. `--dry-run` is always safe.
- `feline lock` validates all domain and app names against a strict
  allowlist to prevent shell injection through `/etc/hosts` updates or
  AppleScript calls.
- `feline scrape` verifies SSL certificates by default — never silently
  downgrades.
- The C dispatcher uses `execvp`, not `system()` — no shell expansion on
  subcommand names.

## Architecture

```
feline (C binary)        ← single entry point, ~30KB, dispatches to:
├── feline-download      (bash + curl/yt-dlp)
├── feline-convert       (bash + ffmpeg/magick/pandoc)
├── feline-clean         (bash, native macOS only)
├── feline-context       (Python 3, native macOS only)
├── feline-snap          (Python 3, native macOS only)
├── feline-search        (bash + mdfind)
├── feline-scrape        (Python 3, stdlib only)
└── feline-lock          (bash + launchd + AppleScript)
```

The dispatcher works exactly like `git` does — `feline foo bar` exec's
`feline-foo bar`. You can drop your own `feline-<name>` script into
`/usr/local/bin` and it'll work as a new subcommand automatically.

## License

MIT
