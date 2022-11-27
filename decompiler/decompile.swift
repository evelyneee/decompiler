//
//  decompile.swift
//  decompiler
//
//  Created by charlotte on 2022-11-22.
//

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

func bl(_ raw: String) -> String {
    var comp = raw.components(separatedBy: " ").dropFirst().first
    if let _comp = comp, _comp.hasPrefix("_") {
        comp = String(_comp.dropFirst())
    }
    return (comp ?? "UNKNOWN_FUNCTION") + "(" + regs.x.compactMap(\.value).map(String.init).joined(separator: ", ") + ")"
}

func cmp(_ raw: String) -> String {
    let comp = raw.components(separatedBy: " ").dropFirst().joined().components(separatedBy: ",")
    let dest = comp[0]
    let source = comp[1].dropFirst()
    if let reg = regs.x[String(dest.dropFirst())], String(reg ?? 0) == source {
        return "// stripped out dead code " + raw
    } else {
        indentCount += 1
        return "if (" + dest + " == " + String(source) + ") {"
    }
}

func beq(_ raw: String) -> String {
    var comp = raw.components(separatedBy: " ").dropFirst().first
    if let _comp = comp, _comp.hasPrefix("_") {
        comp = String(_comp.dropFirst())
    }
    return (0..<indentCount).map({ _ in "    " }).joined() +
    (comp ?? "UNKNOWN_FUNCTION") +
    "(" +
    regs.x.compactMap(\.value).map(String.init).joined(separator: ", ") +
    ")"
}
