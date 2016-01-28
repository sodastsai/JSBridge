//
//  ConsoleTests.swift
//  JSBridgeApp
//
//  Copyright 2016 Tien-Che Tsai, and Tickle Labs, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import XCTest
import TCJSBridge

class ConsoleTests: JSBridgeTests, TCJSOutputConsole {
    
    override func setUp() {
        super.setUp()
        TCJSApplication.currentApplication().console.outputConsole = self
    }

    override func tearDown() {
        self.lastConsoleLevel = nil
        self.lastConsoleMessage = nil
        TCJSApplication.currentApplication().console.outputConsole = nil

        super.tearDown()
    }

    var lastConsoleMessage: String?
    var lastConsoleLevel: String?
    func writeConsoleMessage(message: String, level: String, forJavaScriptContext context: JSContext) {
        if context === self.context {
            self.lastConsoleMessage = message
            self.lastConsoleLevel = level
        }
    }

    func testLog() {
        self.context.evaluateScript("application.console.log('XD');")
        XCTAssertEqual("XD", self.lastConsoleMessage)
        XCTAssertEqual("log", self.lastConsoleLevel)
    }

    func testLogWithFormat() {
        self.context.evaluateScript("application.console.log('Answer=%d', 42);")
        XCTAssertEqual("Answer=42", self.lastConsoleMessage)
        XCTAssertEqual("log", self.lastConsoleLevel)
    }

    func testLogWithMultipleObjects() {
        self.context.evaluateScript("application.console.log('Answer', 42);")
        XCTAssertEqual("Answer 42", self.lastConsoleMessage)
        XCTAssertEqual("log", self.lastConsoleLevel)
    }

    func testLogWithFormatAndMultipleObjects() {
        self.context.evaluateScript("application.console.log('Answer=%d', 42, 'Hello');")
        XCTAssertEqual("Answer=42 Hello", self.lastConsoleMessage)
        XCTAssertEqual("log", self.lastConsoleLevel)
    }

    // TODO: Test for info and etc.
    
}
