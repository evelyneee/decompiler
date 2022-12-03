
import Foundation

let str = """
mov x0, #1
cmp x0, #2
b.eq _exit
mov x1, x0
cmp x1, #1
b.eq _exit
mov x0, #2
b _drm
"""

let fns = [
    "_main":
        """
        bl _hello_world
        bl _set_app_env
        bl _call_app_binary
        bl _goodbye
        ret
        """,

    "_goodbye":
        """
        adr x0, goodbye
        bl _puts
        ret
        """,
    "_hello_world":"""
        adr x0, hello_world
        bl _puts
        ret
        """,
    "_set_app_env":
        """
        adr x0, dyld_insert
        adr x1, dylib_path
        mov x2, #1
        bl _setenv
        cmp x0, #0
        adr x1, success
        adr x2, failure
        csel x0, x1, x2, EQ
        bl _puts
        ret
        """,
    "_call_app_binary":
        """
        adr x0, bin_path
        adr x1, bin_path
        bl _execl
        ret
        """,
]

struct Regs {
    var x: [String:Any?]
    var sp: Int
}

var regs: Regs = .init(x: [:], sp: 0)

var indentCount: Int = 0

fns.forEach { name, fn in
    
    regs = .init(x: [:], sp: 0)
    indentCount = 0
    
    var out: [String] = .init()

    let isns = fn.components(separatedBy: "\n")

    for (idx, line) in isns.enumerated() {
        let opc = line.components(separatedBy: " ").first
        switch opc {
        case "mov":
            out.append(mov(line).indent())
        case "adr":
            out.append(adr(line).indent())
        case "bl":
            out.append(branch(line).indent())
        case "cmp":
            out.append(cmp(line))
        case "csel":
            out.append(csel(line).indent())
        case "b.eq":
            if let code = conditionCodes["EQ"] {
                if code {
                    out.append(beq(line).indent())
                } else {
                    #if DEBUG
                    out.append("// stripped out dead code: " + line)
                    #endif
                }
            } else {
                out.append(beq(line).indent())
            }
            conditionCodes.removeValue(forKey: "EQ")
            indentCount -= 1
            out.append("}")
        case "b":
            out.append("return " + branch(line).indent())
        case "ret":
            out.append("return".indent())
        default: out.append((#"__asm__(""# + line + #"")"#).indent())
        }
    }
    
    print("\n")
    print("void " + name.dropFirst() + "(void)" + " {")
    
    print(out.compactMap { "    " + $0 } .joined(separator: "\n"))
    
    if indentCount >= 1 {
        for i in 1...indentCount {
            print((0..<(indentCount - i)).map { _ in "  "}.joined() + "    }")
        }
    }
    
    print("}")
}
