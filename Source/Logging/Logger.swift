//
//  Logger.swift
//
//  Copyright (c) 2015 David Robles
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

struct LogFlag : OptionSet {    
    let rawValue: UInt
    
    static let Error = LogFlag(rawValue: 1 << 0) // 0...00001
    static let Warning = LogFlag(rawValue: 1 << 1) // 0...00010
    static let Info = LogFlag(rawValue: 1 << 2) // 0...00100
    static let Debug = LogFlag(rawValue: 1 << 3) // 0...01000
    static let Verbose = LogFlag(rawValue: 1 << 4) // 0...10000
}

/// Debug levels
extension LogFlag {
    static let OffLevel: LogFlag = []
    static let ErrorLevel: LogFlag = [.Error]
    static let WarningLevel: LogFlag = [.Error, .Warning]
    static let InfoLevel: LogFlag = [.Error, .Warning, .Info]
    static let DebugLevel: LogFlag = [.Error, .Warning, .Info, .Debug]
    static let VerboseLevel: LogFlag = [.Error, .Warning, .Info, .Debug, .Verbose]
    
}

let defaultLogLevel = LogFlag.DebugLevel

var logLevel = defaultLogLevel

func resetDefaultDebugLevel() {
    logLevel = defaultLogLevel
}

func Log(_ isAsynchronous: Bool, level: LogFlag, flag: LogFlag, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, string: @autoclosure () -> String) {
    if level.contains(flag) {
        print(string())
    }
}

func LogDebug(_ logText: @autoclosure () -> String, level: LogFlag = logLevel, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, asynchronous async: Bool = true) {
    Log(async, level: level, flag: .Debug, file: file, function: function, line: line, string: logText)
}

func LogInfo(_ logText: @autoclosure () -> String, level: LogFlag = logLevel, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, asynchronous async: Bool = true) {
    Log(async, level: level, flag: .Info, file: file, function: function, line: line, string: logText)
}

func LogWarn(_ logText: @autoclosure () -> String, level: LogFlag = logLevel, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, asynchronous async: Bool = true) {
    Log(async, level: level, flag: .Warning, file: file, function: function, line: line, string: logText)
}

func LogVerbose(_ logText: @autoclosure () -> String, level: LogFlag = logLevel, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, asynchronous async: Bool = true) {
    Log(async, level: level, flag: .Verbose, file: file, function: function, line: line, string: logText)
}

func LogError(_ logText: @autoclosure () -> String, level: LogFlag = logLevel, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, asynchronous async: Bool = false) {
    Log(async, level: level, flag: .Error, file: file, function: function, line: line, string: logText)
}
