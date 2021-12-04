import Darwin

import ArgumentParser
import CodeSign
import Proc
import ProcUtils
import SysCall

let Version = "0.1.4"
let pathEq: [String] = [
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
    "/usr/bin/swift",
    
    "/usr/bin/nc",
]
let pathPrefix: [String] = [
    "/usr/bin/perl",
    "/usr/bin/php",
    "/usr/bin/python",
    "/usr/bin/ruby",
    
    "/usr/bin/tclsh",
    "/usr/bin/wish",
]

class Node {
    let pid: pid_t
    let ppid: pid_t?
    let path: String?
    var args: [String]? = nil
    var msg: String? = nil
    var isRoot: Bool = false
    var children: [Node]
    weak var parent: Node? = nil
    
    init(pid: pid_t, ppid: pid_t?, path: String?) {
        self.pid = pid
        self.ppid = ppid
        self.path = path
        self.children = []
    }

    func sort() {
        children.sort(by: { $0.path ?? "" < $1.path ?? "" })
        for child in children {
            child.sort()
        }
    }

    func printTree(_ indent: Int = 0) {
        let space = String(repeating: " ", count: indent)
        let pid = String(self.pid).padding(toLength: 5, withPad: " ", startingAt: 0)
        var msg = self.msg ?? self.path ?? "nil"
        if let args = self.args {
            msg += " " + args.joined(separator: " ")
        }
        print("\(space)[\(pid)] \(msg)")
        for child in children {
            child.printTree(indent + 2)
        }
    }
}

func check() throws {
    let pids = try Proc.listAllPids().get()
    let requirement = try CodeSign
        .createRequirement(with: CodeSignRequirementString.apple).get()
    let cpid = getpid()
    var nodes = [pid_t: Node]()
    for pid in pids {
        guard pid != 0 && pid != 1 && pid != cpid else { continue }
        let node = Node(
            pid: pid,
            ppid: try? ProcUtils.ppid(pid).get(),
            path: try? Proc.pidPath(pid).get()
        )
        nodes[pid] = node
        guard let code = try? CodeSign.createCode(with: pid).get() else {
            node.msg = "ERR: create code failed (\(node.path ?? "nil"))"
            node.isRoot = true
            continue
        }
        if case .failure(_) = CodeSign
            .checkValidity(for: code, requirement: requirement) {
            
            node.isRoot = true
            continue
        }
        guard let path = node.path else { continue }
        if pathEq.contains(path) ||
            pathPrefix.contains(where: { path.hasPrefix($0) }) {
            
            node.args = (try? SysCall.args(pid).get())?.args
            node.isRoot = true
        }
    }
    for node in nodes.values {
        guard let ppid = node.ppid else { continue }
        guard let parent = nodes[ppid] else { continue }
        node.parent = parent
        parent.children.append(node)
    }
    var roots = [pid_t: Node]()
    for node in nodes.values {
        guard node.isRoot else { continue }
        var root = node
        while root.parent != nil {
            root = root.parent!
        }
        roots[root.pid] = root
    }
    var tree = [Node](roots.values)
    tree.sort(by: { $0.path ?? "" < $1.path ?? "" })
    for node in tree {
        node.sort()
        node.printTree()
    }
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
