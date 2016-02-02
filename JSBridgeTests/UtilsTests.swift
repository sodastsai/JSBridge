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
import TCJSBridge

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

    func testInherits1() {
        self.context.evaluateScript("function A(name) { this.name = name; }")
        self.context.evaluateScript("function B(name, gender) { this.gender = gender; this.constructor.super_.call(this, name); }")
        self.context.evaluateScript("util.inherits(B, A);")
        self.context.evaluateScript("var b = new B('Peter', 'Male');")
        self.context.evaluateScript("A.prototype.hi = function() { return 'Hi, ' + this.name; }")
        XCTAssertEqual(self.context.evaluateScript("b.hi();").toString(), "Hi, Peter")
        XCTAssertTrue(self.context.evaluateScript("b instanceof B").toBool())
        XCTAssertTrue(self.context.evaluateScript("b instanceof A").toBool())
        XCTAssertFalse(self.context.evaluateScript("b instanceof Array").toBool())
        XCTAssertEqual(self.context.evaluateScript("b.constructor.super_;"), self.context.evaluateScript("A;"))
    }

    func testInherits2() {
        let A = self.context.evaluateScript("function A(name) { this.name = name; }; A;")
        let B = self.context.evaluateScript("function B(name, gender) { this.gender = gender; this.constructor.super_.call(this, name); }; B;")
        self.context.evaluateScript("util.inherits(B, A);")

        let b = B.constructWithArguments(["Peter", "Male"])
        XCTAssertTrue(b.isInstanceOf(A))
        XCTAssertTrue(b.isInstanceOf(B))
    }

    func testExtends1() {
        let obj1 = self.context.evaluateScript("(function() { return {answer: 41, name: 'Peter'}; })();")
        let obj2 = self.context.evaluateScript("(function() { return {answer: 42, gender: 'Male'}; })();")
        let obj3 = TCJSUtil.extends(obj1, withObjects: [obj2], context: self.context)

        XCTAssertEqual(obj3.toObject() as! [String: NSObject], ["answer": 42, "gender": "Male", "name": "Peter"])
        XCTAssertTrue(obj1.isEqualToObject(obj3))
    }

    func testExtends2() {
        let obj1 = ["answer": 41, "name": "Peter"]
        let obj2 = ["answer": 42, "gender": "Male"]
        self.context.globalObject.setValue(obj1, forProperty: "obj1")
        self.context.globalObject.setValue(obj2, forProperty: "obj2")
        let obj3 = self.context.evaluateScript("util.extend(obj1, obj2);").toObject() as! [String: NSObject]

        XCTAssertEqual(obj3, ["answer": 42, "gender": "Male", "name": "Peter"])
    }

    func testConstructorBuilder() {
        let builderA = TCJSConstructorBuilder(name: "A")
        builderA.addProperty("name", argumentName: "name", passToSuper: false)
        let A = builderA.buildWithContext(self.context)

        let builderB = TCJSConstructorBuilder(name: "B")
        builderB.addProperty(nil, argumentName: "name", passToSuper: true)
        builderB.addProperty("gender", argumentName: "gender", passToSuper: false)
        let B = builderB.buildWithContext(self.context)

        TCJSUtil.inherits(B, withSuperConstructor: A, context: self.context)

        var greeting: String!
        let block: @convention(block) () -> Void = {
            greeting = "Hi, \(JSContext.currentThis().valueForProperty("name").toString())"
        }
        A.valueForProperty("prototype").setValue(unsafeBitCast(block, AnyObject.self), forProperty: "hi")

        let a = A.constructWithArguments(["Rach"])
        a.invokeMethod("hi", withArguments: [])
        XCTAssertEqual(greeting, "Hi, Rach")

        let b = B.constructWithArguments(["Peter", "Male"])
        b.invokeMethod("hi", withArguments: [])
        XCTAssertEqual(greeting, "Hi, Peter")
        XCTAssertEqual(b.valueForProperty("gender").toString(), "Male")
    }

}
