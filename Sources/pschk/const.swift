//
//  const.swift
//  pschk
//
//  Created by lucky on 11.08.2026.
//

let interestIdentifiers: Set<String> = [
    // Both csh and tcsh use com.apple.csh
    "com.apple.bash",
    "com.apple.csh",
    "com.apple.dash",
    "com.apple.ksh",
    "com.apple.sh",
    "com.apple.zsh",

    "com.apple.perl",
    "com.apple.python3",
    "com.apple.ruby",
    "com.tcltk.tclsh",
    "com.tcltk.wish",
    "com.apple.swift-frontend",
    "com.apple.awk",

    "com.apple.php",
    "com.apple.python",

    "com.apple.jstat",

    "com.apple.osascript",
    "com.apple.automatorCLI",
    "com.apple.shortcuts.ShortcutsCommandLine",
    "com.apple.ScriptMonitor",

    "com.apple.login",
    "com.apple.su",
    "com.apple.find",
    "com.apple.lldb",

    "com.apple.nc",
    "com.apple.openssl",
    "com.apple.curl",
    "com.apple.nscurl",
    "com.apple.tftp",
    "com.apple.tcpdump",
    "com.apple.ssh",
    "com.apple.sftp",
    "com.apple.scp",

    "com.apple.screencapture",
    "com.apple.notifyutil",
    "com.apple.caffeinate",
    "com.apple.safaridriver",
    
    "com.apple.dt.xcode_select.tool-shim-public",
]

let expectedAppleDirectories: Set<String> = [
    "/bin/",
    "/sbin/",
    "/usr/bin/",
    "/usr/sbin/",
    "/usr/lib/",
    "/usr/libexec/",
    "/System/Applications/",
    "/System/Library/",
    "/Library/Apple/",
    "/System/Cryptexes/App/",
    "/System/Cryptexes/OS/",
    "/System/Volumes/Preboot/Cryptexes/App/",
    "/System/Volumes/Preboot/Cryptexes/OS/",
    "/System/iOSSupport/",
    "/System/DriverKit/",
    "/Library/Developer/CommandLineTools/",
    "/Library/Developer/PrivateFrameworks/",
]
