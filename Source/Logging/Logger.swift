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

import UIKit

import Foundation

public struct LogFlag : RawOptionSetType {
    typealias RawValue = UInt
    private var value: UInt = 0
    init(_ value: UInt) { self.value = value }
    public init(rawValue value: UInt) { self.value = value }
    public init(nilLiteral: ()) { self.value = 0 }
    public static var allZeros: LogFlag { return self(0) }
    static func fromMask(raw: UInt) -> LogFlag { return self(raw) }
    public var rawValue: UInt { return self.value }
    
    static var Error: LogFlag { return self(1 << 0) } // 0...00001
    static var Warning: LogFlag { return self(1 << 1) } // 0...00010
    static var Info: LogFlag { return self(1 << 2) } // 0...00100
    static var Debug: LogFlag { return self(1 << 3) } // 0...01000
    static var Verbose: LogFlag { return self(1 << 4) }  // 0...10000
}

public struct LogLevel : RawOptionSetType {
    typealias RawValue = UInt
    private var value: UInt = 0
    init(_ value: UInt) { self.value = value }
    public init(rawValue value: UInt) { self.value = value }
    public init(nilLiteral: ()) { self.value = 0 }
    public static var allZeros: LogLevel { return self(0) }
    static func fromMask(raw: UInt) -> LogLevel { return self(raw) }
    public var rawValue: UInt { return self.value }
    
    static var Off: LogLevel { return self(0) }
    static var Error: LogLevel { return self(LogFlag.Error.rawValue) }
    static var Warning: LogLevel { return self(Error.rawValue | LogFlag.Warning.rawValue) }
    static var Info: LogLevel { return self(Warning.rawValue | LogFlag.Info.rawValue) }
    static var Debug: LogLevel { return self(Info.rawValue | LogFlag.Debug.rawValue) }
    static var Verbose: LogLevel { return self(Debug.rawValue | LogFlag.Verbose.rawValue) }
    static var All: LogLevel { return self(UInt.max) }  // 1111...11111
}

public let defaultLogLevel = LogLevel.Verbose

public var logLevel = defaultLogLevel

public func resetDefaultDebugLevel() {
    logLevel = defaultLogLevel
}

public func SwiftLogMacro(isAsynchronous: Bool, level: LogLevel, flag: LogFlag, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UInt = __LINE__, string: @autoclosure () -> String) {
    if level.rawValue & flag.rawValue != 0 {
        NSLog(string())
    }
}

public func LogDebug(logText: @autoclosure () -> String, level: LogLevel = logLevel, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__, asynchronous async: Bool = true) {
    SwiftLogMacro(async, level, .Debug, file: file, function: function, line: line, logText)
}

public func LogInfo(logText: @autoclosure () -> String, level: LogLevel = logLevel, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__, asynchronous async: Bool = true) {
    SwiftLogMacro(async, level, .Info, file: file, function: function, line: line, logText)
}

public func LogWarn(logText: @autoclosure () -> String, level: LogLevel = logLevel, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__, asynchronous async: Bool = true) {
    SwiftLogMacro(async, level, .Warning, file: file, function: function, line: line, logText)
}

public func LogVerbose(logText: @autoclosure () -> String, level: LogLevel = logLevel, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__, asynchronous async: Bool = true) {
    SwiftLogMacro(async, level, .Verbose, file: file, function: function, line: line, logText)
}

public func LogError(logText: @autoclosure () -> String, level: LogLevel = logLevel, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__, asynchronous async: Bool = false) {
    SwiftLogMacro(async, level, .Error, file: file, function: function, line: line, logText)
}

@objc public class UPnPLogger {
    public class func setLogLevel(aLogLevel: LogLevel) {
        logLevel = aLogLevel
    }
    
    public class func logDebug(logText: String) {
        LogDebug(logText)
    }
    
    public class func logInfo(logText: String) {
        LogInfo(logText)
    }
    
    public class func logWarn(logText: String) {
        LogWarn(logText)
    }
    
    public class func logVerbose(logText: String) {
        LogVerbose(logText)
    }
    
    public class func logError(logText: String) {
        LogError(logText)
    }
}
