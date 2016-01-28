//
//  ConsoleTests.swift
//  JSBridgeApp
//
//  Created by sodas on 1/28/16.
//  Copyright © 2016 JSBridge. All rights reserved.
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
