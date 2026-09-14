import Foundation
import Darwin

import ArgumentParser
import CodeSign
import Proc
import SysCall

let Version = "0.3.0"
let maxPidSize = 5
let szombCommand = "<defunct>"

class Process: Hashable {

    static func == (lhs: Process, rhs: Process) -> Bool { lhs.pid == rhs.pid }
    
    func hash(into hasher: inout Hasher) { hasher.combine(pid) }
    
    let pid: pid_t
    var path: String?
    let args: SysCall.Args?
    let kinfo: kinfo_proc?
    var identifier: String?
    var isShowCommand: Bool = false
    var isShowArgs: Bool = false
    var isShowEnv: Bool = false
    var signature: Signature? = nil
    var reason: Reason? = nil
    var children: [Process]
    var code: SecCode?
    weak var parent: Process? = nil
    
    init(pid: pid_t) {
        self.pid = pid
        self.path = try? Proc.pidPath(pid).get()
        self.args = try? SysCall.args(pid).get()
        self.kinfo = try? SysCall.kinfo(pid).get()
        self.children = []
    }
    
    func getPath() -> String? { self.path ?? self.args?.path }
    
    func createCode() -> Bool {
        self.code = try? CodeSign.createCode(with: self.pid).get()
        let rv = self.code != nil
        if !rv { self.signature = .unavailable }
        return rv
    }
    
    func getIdentifier() -> String? {
        guard let code = self.code else { return nil }
        let information = try? CodeSign
            .copySigningInformation(from: code)
            .get()
        guard let information else { return nil }
        self.identifier = information[kSecCodeInfoIdentifier as String] as? String
        return self.identifier
    }
    
    func checkValidity(for requirement: SecRequirement) -> Bool {
        guard let code = self.code else { return false }
        return (try? CodeSign.checkValidity(for: code, requirement: requirement).get()) != nil
    }
}

func printProcess(_ proc: Process, indent: Int) {
    let spacer = String(repeating: " ", count: indent)
    var pid = String(proc.pid)
    assert(pid.count <= maxPidSize)
    pid = String(repeating: "0", count: maxPidSize - pid.count).appending(pid)
    var isZombie = false
    var uname = "nil"
    if let kinfo = proc.kinfo {
        isZombie = kinfo.kp_proc.p_stat == SZOMB
        uname = String(cString: user_from_uid(kinfo.kp_eproc.e_pcred.p_ruid, 0))
    }
    var command = if isZombie { szombCommand } else { proc.getPath() ?? "nil" }
    if var args = proc.args?.args, proc.isShowArgs {
        if args.first == command { args.removeFirst() }
        command += " " + args.joined(separator: " ")
    }
    if let env = proc.args?.env, proc.isShowEnv {
        command += " " + env.map { "\($0.key)=\($0.value)" }.joined(separator: ";")
    }
    var suffix: [String] = []
    if proc.reason == .location {
        if let identifier = proc.identifier { suffix.append(identifier) }
    }
    if !suffix.isEmpty {
        command += " [\(suffix.joined(separator: ";"))]"
    }
    print("\(spacer)[\(pid)] [\(uname)] \(command)")
}

func walk(_ procs: inout [Process], indent: Int) {
    procs.sort(by: { $0.getPath() ?? "" < $1.getPath() ?? "" })
    for proc in procs {
        if proc.isShowCommand { printProcess(proc, indent: indent) }
        walk(&proc.children, indent: indent + 2)
    }
}

func check(_ opts: Opts) throws {
    let pids = try Proc.listAllPids().get()
    let requirementApple = try CodeSign
        .createRequirement(with: CodeSignRequirementString.apple).get()
    let cpid = getpid()
    var procs = [pid_t: Process]()
    for pid in pids {
        guard pid != 0 && pid != 1 && pid != cpid else { continue }
        let proc = Process(pid: pid)
        proc.isShowCommand = opts.all
        proc.isShowArgs = opts.args
        proc.isShowEnv = opts.env
        procs[pid] = proc
        guard proc.createCode() else {
            proc.isShowCommand = true
            continue
        }
        if proc.checkValidity(for: requirementApple) {
            proc.signature = .apple
            guard let identifier = proc.getIdentifier() else {
                proc.code = nil
                proc.isShowCommand = true
                continue
            }
            proc.code = nil
            if interestIdentifiers.contains(identifier) {
                proc.isShowCommand = true
                proc.isShowArgs = true
            }
            guard let path = proc.getPath() else {
                proc.isShowCommand = true
                continue
            }
            if !isExpectedApplePath(path) {
                proc.reason = .location
                proc.isShowCommand = true
            }
        } else {
            proc.code = nil
            proc.signature = .validity
            proc.isShowCommand = true
        }
    }
    let getResponsiblePid = dlsymGetResponsiblePid()
    for proc in procs.values {
        var ppid = proc.kinfo?.kp_eproc.e_ppid
        if ppid == 1 && getResponsiblePid != nil {
            let rpid = getResponsiblePid!(proc.pid)
            if rpid != proc.pid && rpid != -1 { ppid = rpid }
        }
        guard let ppid = ppid else { continue }
        guard let parent = procs[ppid] else { continue }
        proc.parent = parent
        parent.children.append(proc)
    }
    var roots = [pid_t: Process]()
    for proc in procs.values {
        guard proc.isShowCommand else { continue }
        var root = proc
        while let parent = root.parent {
            root = parent
            root.isShowCommand = true
        }
        roots[root.pid] = root
    }
    var tree = [Process](roots.values)
    walk(&tree, indent: 0)
}

func isExpectedApplePath(_ path: String) -> Bool {
    guard path.hasPrefix("/") else { return false }
    return expectedAppleDirectories.contains { path.hasPrefix($0) }
}

func dlsymGetResponsiblePid() -> ((pid_t) -> pid_t)? {
    let RTLD_NEXT = UnsafeMutableRawPointer(bitPattern: -1)
    let sym = dlsym(
        RTLD_NEXT,
        "responsibility_get_pid_responsible_for_pid",
    )
    if let sym {
        var fn: @convention(c) (pid_t) -> pid_t
        fn = unsafeBitCast(sym, to: type(of: fn))
        return fn
    }
    return nil
}

enum Signature {
    case apple
    case validity
    case unavailable
}

enum Reason {
    case location
}

struct Opts {
    let args: Bool
    let env: Bool
    let all: Bool
}

struct Pschk: ParsableCommand {
    @Flag(help: "Print version and exit")
    var version = false
    
    @Flag(help: "Show arguments for all")
    var args = false
    
    @Flag(help: "Show environment vars")
    var env = false
    
    @Flag(
        name: .short,
        help: "Show all processes, ignore default filter"
    )
    var all = false

    mutating func run() throws {
        if version {
            print(Version)
            return
        }
        try check(Opts(
            args: args,
            env: env,
            all: all
        ))
    }
}

Pschk.main()
