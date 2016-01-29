//
//  UtilsTests.swift
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
import JavaScriptCore

class UtilsTests: JSBridgeTests {
    
    override func setUp() {
        super.setUp()
        self.context.evaluateScript("var util = require('util');")
    }

    func testIsArray() {
        XCTAssertFalse(self.context.evaluateScript("util.isArray('util');").toBool())
        XCTAssertTrue(self.context.evaluateScript("util.isArray([]);").toBool())
        XCTAssertFalse(self.context.evaluateScript("util.isArray({});").toBool())
        XCTAssertTrue(self.context.evaluateScript("util.isArray(['util', util, 42, {answer: 42}]);").toBool())
        XCTAssertFalse(self.context.evaluateScript("util.isArray({list: [1, 2, 3]});").toBool())

        self.context.globalObject.setValue([1, 2, 3], forProperty: "swiftArray")
        XCTAssertTrue(self.context.evaluateScript("util.isArray(swiftArray);").toBool())
    }

    func testIsRegExp() {
        XCTAssertFalse(self.context.evaluateScript("util.isRegExp('util');").toBool())
        XCTAssertFalse(self.context.evaluateScript("util.isRegExp(42);").toBool())
        XCTAssertFalse(self.context.evaluateScript("util.isRegExp(new Date());").toBool())
        XCTAssertTrue(self.context.evaluateScript("util.isRegExp(/[ab]/);").toBool())

        let swiftRegExp = JSValue(newRegularExpressionFromPattern: "[ab]", flags: "i", inContext: self.context)
        self.context.globalObject.setValue(swiftRegExp, forProperty: "swiftRegExp")
        XCTAssertTrue(self.context.evaluateScript("util.isRegExp(swiftRegExp);").toBool())
    }

    func testIsDate() {
        XCTAssertFalse(self.context.evaluateScript("util.isDate('util');").toBool())
        XCTAssertFalse(self.context.evaluateScript("util.isDate(42);").toBool())
        XCTAssertTrue(self.context.evaluateScript("util.isDate(new Date());").toBool())
        XCTAssertFalse(self.context.evaluateScript("util.isDate(/[ab]/);").toBool())

        self.context.globalObject.setValue(NSDate(), forProperty: "swiftDate")
        XCTAssertTrue(self.context.evaluateScript("util.isDate(swiftDate);").toBool())
    }

    func testIsFunction() {
        XCTAssertFalse(self.context.evaluateScript("util.isFunction('util');").toBool())
        XCTAssertTrue(self.context.evaluateScript("util.isFunction(function() {});").toBool())
        XCTAssertTrue(self.context.evaluateScript("function add() {}; util.isFunction(add);").toBool())
    }

    func testIsError() {
        XCTAssertTrue(self.context.evaluateScript("util.isError(new Error());").toBool())
        XCTAssertFalse(self.context.evaluateScript("util.isError(42);").toBool())
        XCTAssertFalse(self.context.evaluateScript("util.isError({});").toBool())

        let swiftError = JSValue(newErrorFromMessage: "QQ", inContext: self.context)
        self.context.globalObject.setValue(swiftError, forProperty: "swiftError")
        XCTAssertTrue(self.context.evaluateScript("util.isError(swiftError);").toBool())
    }

    func testIsUndefined() {
        XCTAssertTrue(self.context.evaluateScript("util.isUndefined(global.aa);").toBool())
        XCTAssertFalse(self.context.evaluateScript("util.isUndefined(require);").toBool())
    }

    // TOOD: Tests for `isNull`, `isBoolean`, `isNumber`, `isString`, and `isObject`

    func testFormat() {
        XCTAssertEqual(self.context.evaluateScript("util.format('XD')").toString(), "XD")
        XCTAssertEqual(self.context.evaluateScript("util.format(42)").toString(), "42")
        XCTAssertEqual(self.context.evaluateScript("util.format(42, 'Answer')").toString(), "42 Answer")
        XCTAssertEqual(self.context.evaluateScript("util.format('AA~', 'XD')").toString(), "AA~ XD")
        XCTAssertEqual(self.context.evaluateScript("util.format('======%s~', 'XDDD')").toString(), "======XDDD~")
        XCTAssertEqual(self.context.evaluateScript("util.format('%s~', 'XD', 4242)").toString(), "XD~ 4242")
        XCTAssertEqual(self.context.evaluateScript("util.format('~%d=', -4231)").toString(), "~-4231=")
        XCTAssertEqual(self.context.evaluateScript("util.format('~%j=', {answer: 42})").toString(), "~{\"answer\":42}=")
        XCTAssertEqual(self.context.evaluateScript("util.format('~%j=', 42)").toString(), "~undefined=")
        XCTAssertEqual(self.context.evaluateScript("util.format('~%j=', new Error())").toString(),
            "~{\"line\":1,\"column\":30}=")
        XCTAssertEqual(self.context.evaluateScript("util.format('~%d=', new Date())").toString(), "~NaN=")
    }
    
}
