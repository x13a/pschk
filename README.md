# pschk

Find suspicious processes.

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
❯ pschk
[74437] /Applications/Firefox.app/Contents/MacOS/firefox
[57292] /Applications/Firefox.app/Contents/MacOS/plugin-container.app/Contents/MacOS/plugin-container
[78984] /Applications/Firefox.app/Contents/MacOS/plugin-container.app/Contents/MacOS/plugin-container
[74552] /Applications/Firefox.app/Contents/MacOS/plugin-container.app/Contents/MacOS/plugin-container
[74449] /Applications/Firefox.app/Contents/MacOS/plugin-container.app/Contents/MacOS/plugin-container
[74448] /Applications/Firefox.app/Contents/MacOS/plugin-container.app/Contents/MacOS/plugin-container
[63463] /Applications/Fork.app/Contents/MacOS/Fork
...
```
