//
//  RequireTests.swift
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

class RequireTests: JSBridgeTests {
    
    override func setUp() {
        super.setUp()
        let mainModule = self.context.globalObject.valueForProperty("module").toObjectOfClass(TCJSModule) as! TCJSModule
        mainModule.paths.addObject(self.bundle.bundlePath)
    }

    func testRequireUtil() {
        XCTAssertFalse(self.context.globalObject.hasProperty("util"))
        self.context.evaluateScript("var util = require('util');")
        XCTAssertTrue(self.context.globalObject.hasProperty("util"))
        self.context.evaluateScript("var util_format = util.format;")
        XCTAssertFalse(self.context.globalObject.valueForProperty("util_format").isUndefined)
    }

    func testRequireNormalFile() {
        let globalObject = self.context.globalObject

        XCTAssertTrue(globalObject.valueForProperty("garbage").isUndefined)
        globalObject.setValue(48, forProperty: "overrided")
        globalObject.setValue(0, forProperty: "loadCount")

        self.context.evaluateScript("var test = require('RequireTests.js');")
        XCTAssertEqual(globalObject.valueForProperty("test").valueForProperty("answer").toNumber(), 42)
        XCTAssertEqual(globalObject.valueForProperty("test").valueForProperty("name").toString(), "Tickle")
        XCTAssertEqual(globalObject.valueForProperty("test").valueForProperty("twentyFive").toNumber(), 25)
        XCTAssertEqual(globalObject.valueForProperty("loadCount").toNumber(), 1)

        XCTAssertTrue(globalObject.valueForProperty("garbage").isUndefined)
        XCTAssertEqual(globalObject.valueForProperty("overrided").toNumber(), 44)

        self.context.evaluateScript("var test2 = require('RequireTests.js');")
        XCTAssertEqual(globalObject.valueForProperty("loadCount").toNumber(), 1)
    }

    func testResolve() {
        XCTAssertEqual(self.context.evaluateScript("require.resolve('RequireTests.js');").toString(),
            self.bundle.pathForResource("RequireTests", ofType: "js"))
        XCTAssertTrue(self.context.evaluateScript("require.resolve('11RequireTests.js');").isUndefined)
    }

    func testClearRequireCache() {
        let globalObject = self.context.globalObject
        globalObject.setValue(0, forProperty: "loadCount")
        self.context.evaluateScript("var test = require('RequireTests.js');")
        XCTAssertEqual(globalObject.valueForProperty("loadCount").toNumber(), 1)

        self.context.evaluateScript("var test2 = require('RequireTests.js');")
        XCTAssertEqual(globalObject.valueForProperty("loadCount").toNumber(), 1)

        self.context.evaluateScript("module.clearRequireCache();")

        self.context.evaluateScript("var test3 = require('RequireTests.js');")
        XCTAssertEqual(globalObject.valueForProperty("loadCount").toNumber(), 2)
    }
}
