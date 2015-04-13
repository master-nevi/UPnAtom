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

struct LogFlag : RawOptionSetType {
    typealias RawValue = UInt
    private var _value: UInt = 0
    init(_ value: UInt) { self._value = value }
    init(rawValue value: UInt) { self._value = value }
    init(nilLiteral: ()) { self._value = 0 }
    static var allZeros: LogFlag { return self(0) }
    static func fromMask(raw: UInt) -> LogFlag { return self(raw) }
    var rawValue: UInt { return self._value }
    
    static var Error: LogFlag { return self(1 << 0) } // 0...00001
    static var Warning: LogFlag { return self(1 << 1) } // 0...00010
    static var Info: LogFlag { return self(1 << 2) } // 0...00100
    static var Debug: LogFlag { return self(1 << 3) } // 0...01000
    static var Verbose: LogFlag { return self(1 << 4) }  // 0...10000
}

struct LogLevel : RawOptionSetType {
    typealias RawValue = UInt
    private var _value: UInt = 0
    init(_ value: UInt) { self._value = value }
    init(rawValue value: UInt) { self._value = value }
    init(nilLiteral: ()) { self._value = 0 }
    static var allZeros: LogLevel { return self(0) }
    static func fromMask(raw: UInt) -> LogLevel { return self(raw) }
    var rawValue: UInt { return self._value }
    
    static var Off: LogLevel { return self(0) }
    static var Error: LogLevel { return self(LogFlag.Error.rawValue) }
    static var Warning: LogLevel { return self(Error.rawValue | LogFlag.Warning.rawValue) }
    static var Info: LogLevel { return self(Warning.rawValue | LogFlag.Info.rawValue) }
    static var Debug: LogLevel { return self(Info.rawValue | LogFlag.Debug.rawValue) }
    static var Verbose: LogLevel { return self(Debug.rawValue | LogFlag.Verbose.rawValue) }
    static var All: LogLevel { return self(UInt.max) }
}

let defaultLogLevel = LogLevel.Debug

var logLevel = defaultLogLevel

func resetDefaultDebugLevel() {
    logLevel = defaultLogLevel
}

func Log(isAsynchronous: Bool, level: LogLevel, flag: LogFlag, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UInt = __LINE__, @autoclosure string: () -> String) {
    if level.rawValue & flag.rawValue != 0 {
        println(string())
    }
}

func LogDebug(@autoclosure logText: () -> String, level: LogLevel = logLevel, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__, asynchronous async: Bool = true) {
    Log(async, level, .Debug, file: file, function: function, line: line, logText)
}

func LogInfo(@autoclosure logText: () -> String, level: LogLevel = logLevel, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__, asynchronous async: Bool = true) {
    Log(async, level, .Info, file: file, function: function, line: line, logText)
}

func LogWarn(@autoclosure logText: () -> String, level: LogLevel = logLevel, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__, asynchronous async: Bool = true) {
    Log(async, level, .Warning, file: file, function: function, line: line, logText)
}

func LogVerbose(@autoclosure logText: () -> String, level: LogLevel = logLevel, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__, asynchronous async: Bool = true) {
    Log(async, level, .Verbose, file: file, function: function, line: line, logText)
}

func LogError(@autoclosure logText: () -> String, level: LogLevel = logLevel, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__, asynchronous async: Bool = false) {
    Log(async, level, .Error, file: file, function: function, line: line, logText)
}
