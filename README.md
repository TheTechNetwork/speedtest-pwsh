[![GitHub Release Date - Published_At](https://img.shields.io/github/release-date/TheTechNetwork/speedtest-pwsh)](https://github.com/TheTechNetwork/speedtest-pwsh/releases)
[![GitHub Downloads - All Releases](https://img.shields.io/github/downloads/TheTechNetwork/speedtest-pwsh/total)](https://github.com/TheTechNetwork/speedtest-pwsh/releases)

# Speedtest from the command line — Windows, Linux, macOS

One command runs a speed test on any platform. No browsing, no unzipping — the script handles everything and cleans up after itself.

> [!NOTE]
> This project is not affiliated with Ookla or Speedtest.net. It is a wrapper around their official [Speedtest CLI](https://www.speedtest.net/apps/cli).

## Usage

The URL [speed.it2.sh](https://speed.it2.sh) auto-detects your OS and serves the right script.

### Windows — PowerShell

```powershell
irm speed.it2.sh | iex
```

**Command Prompt:**

```bat
powershell -c "irm speed.it2.sh | iex"
```

**With arguments:**

```powershell
iex "& { $(iwr speed.it2.sh) } --servers"
```

### Linux / macOS — bash

```bash
curl -sL speed.it2.sh | bash
```

**With arguments:**

```bash
curl -sL speed.it2.sh | bash -s -- --servers
```

## How it works

- The Cloudflare Worker at `speed.it2.sh` reads the `User-Agent` header and serves `speedtest.ps1` to Windows/PowerShell clients and `speedtest.sh` to Linux/macOS clients
- The script detects your OS and CPU architecture (x86\_64 / aarch64)
- Scrapes the [Speedtest CLI](https://www.speedtest.net/apps/cli) download page for the correct package
- Downloads, extracts, and runs the binary
- Cleans up all temporary files on exit

**Supported platforms:**

| OS | Architectures |
|---|---|
| Windows | x64 |
| Linux | x86\_64, aarch64 |
| macOS | Intel (x86\_64), Apple Silicon (aarch64) |

## License Information

> [!WARNING]
> Your use of this script constitutes acceptance of the Ookla EULA, Terms of Use, and Privacy Policy. The script automatically accepts these on your behalf via `--accept-license` and `--accept-gdpr`. Do not use this script if you do not agree.

```
You may only use this Speedtest software and information generated
from it for personal, non-commercial use, through a command line
interface on a personal computer. Your use of this software is subject
to the End User License Agreement, Terms of Use and Privacy Policy at
these URLs:

  https://www.speedtest.net/about/eula
  https://www.speedtest.net/about/terms
  https://www.speedtest.net/about/privacy
```

## Speedtest CLI options

Pass any arguments directly — they are forwarded to the Speedtest CLI unchanged.

```
Usage: speedtest [<options>]
  -h, --help                        Print usage information
  -V, --version                     Print version number
  -L, --servers                     List nearest servers
  -s, --server-id=#                 Specify a server from the server list using its id
  -I, --interface=ARG               Attempt to bind to the specified interface when connecting to servers
  -i, --ip=ARG                      Attempt to bind to the specified IP address when connecting to servers
  -o, --host=ARG                    Specify a server, from the server list, using its host's fully qualified domain name
  -p, --progress=yes|no             Enable or disable progress bar
  -P, --precision=#                 Number of decimals to use (0-8, default=2)
  -f, --format=ARG                  Output format (see below for valid formats)
      --progress-update-interval=#  Progress update interval (100-1000 milliseconds)
  -u, --unit[=ARG]                  Output unit for displaying speeds
  -a                                Shortcut for [-u auto-decimal-bits]
  -A                                Shortcut for [-u auto-decimal-bytes]
  -b                                Shortcut for [-u auto-binary-bits]
  -B                                Shortcut for [-u auto-binary-bytes]
      --selection-details           Show server selection details
  -v                                Logging verbosity. Specify multiple times for higher verbosity
      --output-header               Show output header for CSV and TSV formats

Valid output formats: human-readable (default), csv, tsv, json, jsonl, json-pretty
```
