
import Foundation

func mov(_ raw: String) -> (String) {
    let comp = raw.components(separatedBy: " ").dropFirst().joined().components(separatedBy: ",")
    let dest = comp[0]
    var source = comp[1]
    if source.first == "#" {
        source = String(source.dropFirst())
    }
    if dest.hasPrefix("x") || dest.hasPrefix("w") {
        if source.hasPrefix("x") || source.hasPrefix("w") {
            regs.x[String(dest.dropFirst())] = regs.x[String(source.dropFirst())]
        } else {
            regs.x[String(dest.dropFirst())] = Int(source)
        }
    }
    return dest + " = " + source
}

func adr(_ raw: String) -> (String) {
    let comp = raw.components(separatedBy: " ").dropFirst().joined().components(separatedBy: ",")
    let dest = comp[0]
    let source = comp[1]
    if dest.hasPrefix("x") || dest.hasPrefix("w") {
        regs.x[String(dest.dropFirst())] = source
    }
    return dest + " = " + source
}

func branch(_ raw: String) -> String {
    var comp = raw.components(separatedBy: " ").dropFirst().first
    if let _comp = comp, _comp.hasPrefix("_") {
        comp = String(_comp.dropFirst())
    }
    return (comp ?? "UNKNOWN_FUNCTION") + "(" + regs.x.compactMap(\.value).compactMap { if let num = $0 as? Int { return String(num) }; return String(describing: $0) }.joined(separator: ", ") + ")"
}

var conditionCodes: [String: Bool] = [:]

func cmp(_ raw: String) -> String {
    let comp = raw.components(separatedBy: " ").dropFirst().joined().components(separatedBy: ",")
    let dest = comp[0]
    let source = comp[1].dropFirst()
    if let register = regs.x[String(dest.dropFirst())],
       let reg = register as? Int,
       String(reg) != source {
        regs.x[String(dest.dropFirst())] = nil
        conditionCodes["EQ"] = true
        #if DEBUG
        return "// stripped out dead code: " + raw
        #else
        return ""
        #endif
    } else {
        regs.x[String(dest.dropFirst())] = nil
        conditionCodes["EQ"] = false
        indentCount += 1
        return "if (" + dest + " == " + String(source) + ") {"
    }
}

func beq(_ raw: String) -> String {
    var comp = raw.components(separatedBy: " ").dropFirst().first
    if let _comp = comp, _comp.hasPrefix("_") {
        comp = String(_comp.dropFirst())
    }
    let ret = (comp ?? "UNKNOWN_FUNCTION") +
    "(" +
    regs.x.compactMap(\.value).compactMap { $0 as? Int }.map(String.init).joined(separator: ", ") +
    ")"
    regs.x = [:] // can't trust regs after function call
    return ret
}

func csel(_ raw: String) -> String {
    let comp = raw.components(separatedBy: " ").dropFirst().joined().components(separatedBy: ",")
    let dest = comp[0]
    let one = comp[1]
    let two = comp[2]
    let code = comp[3]
    regs.x[String(one.dropFirst())] = nil
    regs.x[String(two.dropFirst())] = nil
    regs.x[String(dest.dropFirst())] = ((conditionCodes[code] == true) ? two : one)
    return "// csel"
}

extension String {
    func indent() -> String {
        if indentCount >= 0 {
            return (0..<indentCount).map({ _ in "    " }).joined() + self
        }
        return self
    }
}
