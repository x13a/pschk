import Darwin

import ArgumentParser
import CodeSign
import Proc

let VERSION = "0.1.0"

func check() throws {
    let pids = try Proc.listAllPids().get()
    let requirement = try CodeSign.createRequirement(with: CodeSignRequirementString.apple).get()
    let cpid = getpid()
    for pid in pids {
        guard pid != 0 && pid != 1 && pid != cpid else { continue }
        guard let code = try? CodeSign.createCode(with: pid).get() else {
            let path = (try? Proc.pidPath(pid).get()) ?? ""
            print("[\(pid)] create code failed on: \(path)")
            continue
        }
        if case .failure(_) = CodeSign.checkValidity(for: code, requirement: requirement) {
            let path = (try? Proc.pidPath(pid).get()) ?? ""
            print("[\(pid)] \(path)")
        }
    }
}

struct Pschk: ParsableCommand {
    @Flag(help: "Print version and exit")
    var version = false

    mutating func run() throws {
        if version {
            print(VERSION)
            return
        }
        try check()
    }
}

Pschk.main()
