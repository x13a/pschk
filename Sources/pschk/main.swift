import Foundation
import Darwin

import ArgumentParser
import CodeSign
import Proc
import SysCall

let Version = "0.2.1"
let pathEq: [String] = [
    "/bin/bash",
    "/bin/csh",
    "/bin/dash",
    "/bin/ksh",
    "/bin/sh",
    "/bin/tcsh",
    "/bin/zsh",
    
    "/bin/cp",
    "/bin/mv",
    "/usr/bin/find",
    "/usr/bin/grep",
    
    "/usr/bin/osascript",
    "/usr/bin/java",
    "/usr/bin/javaws",
    "/usr/bin/jrunscript",
    "/usr/bin/jshell",
    "/usr/bin/swift",
    "/usr/bin/awk",
    
    "/usr/bin/env",
    "/usr/bin/open",
    "/usr/bin/login",
    "/usr/bin/su",
    "/usr/bin/sudo",
    "/usr/bin/crontab",
    
    "/usr/bin/nc",
    "/usr/bin/openssl",
    "/usr/bin/curl",
    "/usr/bin/tftp",
    "/usr/sbin/tcpdump",
]
let pathPrefix: [String] = [
    "/usr/bin/perl",
    "/usr/bin/php",
    "/usr/bin/python",
    "/usr/bin/ruby",
    
    "/usr/bin/tclsh",
    "/usr/bin/wish",

    "/System/Library/CoreServices/ScriptMonitor",
]
let maxPidSize = 5
let szombCommand = "<defunct>"

class Node: Hashable {
    static func == (lhs: Node, rhs: Node) -> Bool {
        lhs.pid == rhs.pid
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(pid)
    }
    
    let pid: pid_t
    var path: String?
    let args: SysCall.Args?
    let kinfo: kinfo_proc?
    var isShowCommand: Bool = false
    var isShowArgs: Bool = false
    var isShowEnv: Bool = false
    var state: State? = nil
    var children: [Node]
    var code: SecCode?
    weak var parent: Node? = nil
    
    init(pid: pid_t) {
        self.pid = pid
        self.path = try? Proc.pidPath(pid).get()
        self.args = try? SysCall.args(pid).get()
        self.kinfo = try? SysCall.kinfo(pid).get()
        self.children = []
    }
    
    func getPath() -> String? {
        self.path ?? self.args?.path
    }
    
    func createCode() -> Bool {
        self.code = try? CodeSign.createCode(with: self.pid).get()
        let rv = self.code != nil
        if !rv {
            self.state = .code
        }
        return rv
    }
    
    func checkValidity(for requirement: SecRequirement) -> Bool {
        guard let code = self.code else {
            return false
        }
        return (try? CodeSign.checkValidity(for: code, requirement: requirement).get()) != nil
    }
}

func printNode(_ node: Node, indent: Int) {
    let spacer = String(repeating: " ", count: indent)
    var pid = String(node.pid)
    assert(pid.count <= maxPidSize)
    pid = String(
        repeating: "0",
        count: maxPidSize - pid.count).appending(pid)
    var isZombie = false
    var uname = "nil"
    if let kinfo = node.kinfo {
        isZombie = kinfo.kp_proc.p_stat == SZOMB
        uname = String(cString: 
            user_from_uid(kinfo.kp_eproc.e_pcred.p_ruid, 0))
    }
    var command = if isZombie { szombCommand }
        else { node.getPath() ?? "nil" }
    if var args = node.args?.args, node.isShowArgs {
        if args.first == command {
           args.removeFirst()
        }
        command += " " + args.joined(separator: " ")
    }
    if let env = node.args?.env, node.isShowEnv {
        command += " " + env.map { "\($0.key)=\($0.value)" }
            .joined(separator: ";")
    }
    print("\(spacer)[\(pid)] [\(uname)] \(command)")
}

func walk(_ tree: inout [Node], indent: Int) {
    tree.sort(by: { $0.getPath() ?? "" < $1.getPath() ?? "" })
    for node in tree {
        if node.isShowCommand {
            printNode(node, indent: indent)
        }
        walk(&node.children, indent: indent + 2)
    }
}

func check(_ opts: Opts) throws {
    let pids = try Proc.listAllPids().get()
    let requirementApple = try CodeSign
        .createRequirement(with: CodeSignRequirementString.apple).get()
    let cpid = getpid()
    var nodes = [pid_t: Node]()
    for pid in pids {
        guard pid != 0 && pid != 1 && pid != cpid else { continue }
        let node = Node(pid: pid)
        node.isShowCommand = opts.all
        node.isShowArgs = opts.args
        node.isShowEnv = opts.env
        nodes[pid] = node
        guard node.createCode() else {
            node.isShowCommand = true
            continue
        }
        if node.checkValidity(for: requirementApple) {
            
            node.code = nil
            node.state = .apple
            guard let path = node.getPath() else { continue }
            if pathEq.contains(path) ||
                pathPrefix.contains(where: { path.hasPrefix($0) }) {
                
                node.isShowArgs = true
                node.isShowCommand = true
            }
        } else {
            node.code = nil
            node.state = .validity
            node.isShowCommand = true
        }
    }
    let RTLD_NEXT = UnsafeMutableRawPointer(bitPattern: -1)
    var getResponsiblePid: @convention(c) (pid_t) -> pid_t
    getResponsiblePid = unsafeBitCast(dlsym(
        RTLD_NEXT,
        "responsibility_get_pid_responsible_for_pid"
    ), to: type(of: getResponsiblePid))
    for node in nodes.values {
        var ppid = node.kinfo?.kp_eproc.e_ppid
        if ppid == 1 {
            let rpid = getResponsiblePid(node.pid)
            if rpid != node.pid && rpid != -1 {
                ppid = rpid
            }
        }
        guard let ppid = ppid else { continue }
        guard let parent = nodes[ppid] else { continue }
        node.parent = parent
        parent.children.append(node)
    }
    var roots = [pid_t: Node]()
    for node in nodes.values {
        guard node.isShowCommand else { continue }
        var root = node
        while let parent = root.parent {
            root = parent
            root.isShowCommand = true
        }
        roots[root.pid] = root
    }
    var tree = [Node](roots.values)
    walk(&tree, indent: 0)
}

enum State {
    case apple
    case code
    case validity
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
