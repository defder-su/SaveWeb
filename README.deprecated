<h1 align="center">SaveWeb</h1>

<p align="center">The legacy Web gives us the familiar addressing system. Let's use it, however saving data availability.</p>

## Features:

- Save web page by URL (using wget and wayback_machine_downloader).
- Store the library in IPFS MFS.
- Share saved versions, using IPFS PubSub.

---

## Installation (Linux, macOS):

Install [go-ipfs](https://docs.ipfs.io/install/command-line/), [wget](https://www.gnu.org/software/wget/), [jq](https://stedolan.github.io/jq/download/), [htmlq](https://github.com/mgdm/htmlq/) and [Wayback Machine Downloader](https://github.com/ImportTaste/wayback-machine-downloader).

Clone the repository, open a terminal in the folder and run `./install.sh`

---

## Installation (Windows):

Install [WSL](https://docs.microsoft.com/en-us/windows/wsl/install-win10) (requires about 2GB disk space), [Cygwin](https://www.cygwin.com/), [Git Bash](http://git-scm.com), or some other tool that enables Bash functionality in Windows.

Follow the above section.

---

## Usage:

Open a terminal and run `sw` with arguments.

### Save:
`sw save http://www.example.com/page.htm`
`sw save urls collection.txt`
`sw save urls opera_bookmarks.json`

### Present saved versions:
`sw present http://www.example.com/page.htm`

### List URLs which were attempted to be saved:
`sw history`

---

## TODO:

Support `--help` option for all commands.
Support reading stdin in `url` subcommands, like `cat` supports `cat <<< "1"` and `echo "1" | cat`.
Return various exit codes.

---

## Related Projects:

- [SaveSites](https://github.com/defder-su/SaveSites)

- [IPFS](https://ipfs.io)

- [ZeroNet](https://zeronet.dev)

