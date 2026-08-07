//
//  Shell.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/23.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Foundation

@discardableResult
func shell(_ launchPath: String, arguments: [String]) -> (outStr: String, err: String) {
    let process = Process()
    if #available(macOS 10.13, *) {
        process.executableURL = URL(fileURLWithPath: launchPath)
    } else {
        process.launchPath = launchPath
    }
    process.arguments = arguments
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = errorPipe
    
    do {
        if #available(macOS 10.13, *) {
            try process.run()
        } else {
            process.launch()
        }
    } catch {
        return ("", error.localizedDescription)
    }
    
    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let outputStr = String(data: outputData, encoding: .utf8)
    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
    let errorStr = String(data: errorData, encoding: .utf8)
    
    return (outputStr ?? "", errorStr ?? "")
}

@discardableResult
func shell(_ launchPath: String, arguments: String...) -> (outStr: String, err: String) {
    return shell(launchPath, arguments: arguments)
}

@discardableResult
func shellAsync(_ launchPath: String, arguments: String...) async -> (outStr: String, err: String) {
    return await withCheckedContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).async {
            let result = shell(launchPath, arguments: arguments)
            continuation.resume(returning: result)
        }
    }
}
