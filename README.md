# pschk

Check for suspicious processes on macOS

The app shows all running processes that are not signed by Apple as a tree.
Plus it shows Apple signed running processes like shells, script languages 
and so on that may be used for malicious activity.

## Installation

```sh
$ make
$ [sudo] make install
```
or
```sh
$ brew tap x13a/tap
$ brew install x13a/tap/pschk
```

## Usage

```text
USAGE: pschk [--version] [--args] [--env] [-a]

OPTIONS:
  --version               Print version and exit
  --args                  Show arguments for all
  --env                   Show environment vars
  -a                      Show all processes, ignore default filter
  -h, --help              Show help information.
```

## Example

```sh
~
❯ [sudo] pschk
[74437] [user] /Applications/Firefox.app/Contents/MacOS/firefox
  [78984] [user] /Applications/Firefox.app/Contents/MacOS/plugin-container.app/Contents/MacOS/plugin-container
  [74448] [user] /Applications/Firefox.app/Contents/MacOS/plugin-container.app/Contents/MacOS/plugin-container
  [74552] [user] /Applications/Firefox.app/Contents/MacOS/plugin-container.app/Contents/MacOS/plugin-container
  [74449] [user] /Applications/Firefox.app/Contents/MacOS/plugin-container.app/Contents/MacOS/plugin-container
  [87122] [user] /Applications/Firefox.app/Contents/MacOS/plugin-container.app/Contents/MacOS/plugin-container
[74015] [user] /Applications/Fork.app/Contents/MacOS/Fork
...
```

## License

[![GNU GPLv3 Image](https://www.gnu.org/graphics/gplv3-127x51.png)](https://www.gnu.org/licenses/gpl-3.0.en.html)
