
import Foundation

let str = """
mov x0, #1
cmp x0, #2
b.eq _exit
"""

var out: [String] = .init()

struct Regs {
    var x: [String:Int?]
    var sp: Int
}

var regs: Regs = .init(x: [:], sp: 0)

var indentCount: Int = 0

for line in str.components(separatedBy: "\n") {
    let opc = line.components(separatedBy: " ").first
    switch opc {
    case "mov":
        out.append(mov(line))
    case "bl":
        out.append(bl(line))
    case "cmp":
        out.append(cmp(line))
    case "b.eq":
        if let code = conditionCodes["EQ"] {
            if code {
                out.append(beq(line))
            } else {
                out.append("// stripped out dead code: " + line)
            }
        } else {
            out.append(beq(line))
        }
    default: continue
    }
}

print("---------- DISASM -----------")

print(str)

print("---------- DECOMP -----------")

print(out.joined(separator: "\n"))

if indentCount != 0 {
    for i in 1...indentCount {
        print((0..<(indentCount - i)).map { _ in "  "}.joined() + "}")
    }
}
