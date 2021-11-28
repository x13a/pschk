import Darwin

import ArgumentParser
import CodeSign
import Proc

let Version = "0.1.1"
let pathBinary: [String] = [
    "/bin/bash",
    "/bin/csh",
    "/bin/dash",
    "/bin/ksh",
    "/bin/sh",
    "/bin/tcsh",
    "/bin/zsh",
    
    "/usr/bin/osascript",
    "/usr/bin/java",
    "/usr/bin/javaws",
    "/usr/bin/jrunscript",
    "/usr/bin/jshell",
    "/usr/bin/ruby",
    "/usr/bin/swift",
    
    "/usr/bin/nc",
]
let pathContains: [String] = [
    "perl",
    "php",
    "python",
    
    "tclsh",
    "wish",
]

func check() throws {
    let pids = try Proc.listAllPids().get()
    let requirement = try CodeSign.createRequirement(with: CodeSignRequirementString.apple).get()
    let cpid = getpid()
    var results = [(pid_t, String)]()
    for pid in pids {
        guard pid != 0 && pid != 1 && pid != cpid else { continue }
        let path = getPidPath(pid)
        guard let code = try? CodeSign.createCode(with: pid).get() else {
            results.append((pid, "ERR: create code failed on \(path)"))
            continue
        }
        
        if case .failure(_) = CodeSign.checkValidity(for: code, requirement: requirement) {
            results.append((pid, path))
            continue
        }
        for str in pathBinary {
            if path == str {
                results.append((pid, path))
            }
        }
        for str in pathContains {
            if path.contains(str) {
                results.append((pid, path))
            }
        }
    }
    results.sort(by: { $0.1 < $1.1 })
    for result in results {
        printMsg(result.0, result.1)
    }
}

func printMsg(_ pid: pid_t, _ msg: String) {
    let pid_str = String(pid).padding(toLength: 5, withPad: " ", startingAt: 0)
    print("[\(pid_str)] \(msg)")
}

func getPidPath(_ pid: pid_t) -> String {
    return (try? Proc.pidPath(pid).get()) ?? "nil"
}

struct Pschk: ParsableCommand {
    @Flag(help: "Print version and exit")
    var version = false

    mutating func run() throws {
        if version {
            print(Version)
            return
        }
        try check()
    }
}

Pschk.main()
