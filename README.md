# pschk

Check for suspicious processes on macOS.

This app will show you all running processes that are not signed by Apple.
Plus it will show Apple signed running processes like shells, script languages 
and so on that can be used for malicious activity.

## Installation

```sh
$ make
$ sudo make install
```
or
```sh
$ brew tap x13a/tap
$ brew install x13a/tap/pschk
```

## Usage

```text
USAGE: pschk [--version]

OPTIONS:
  --version               Print version and exit
  -h, --help              Show help information.
```

## Example

```sh
~
❯ [sudo] pschk
[74437] /Applications/Firefox.app/Contents/MacOS/firefox
  [78984] /Applications/Firefox.app/Contents/MacOS/plugin-container.app/Contents/MacOS/plugin-container
  [74448] /Applications/Firefox.app/Contents/MacOS/plugin-container.app/Contents/MacOS/plugin-container
  [74552] /Applications/Firefox.app/Contents/MacOS/plugin-container.app/Contents/MacOS/plugin-container
  [74449] /Applications/Firefox.app/Contents/MacOS/plugin-container.app/Contents/MacOS/plugin-container
  [87122] /Applications/Firefox.app/Contents/MacOS/plugin-container.app/Contents/MacOS/plugin-container
[74015] /Applications/Fork.app/Contents/MacOS/Fork
...
```

## License

[![GNU GPLv3 Image](https://www.gnu.org/graphics/gplv3-127x51.png)](https://www.gnu.org/licenses/gpl-3.0.en.html)
