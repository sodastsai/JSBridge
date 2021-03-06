//
//  ExtraModulesTests.swift
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

class ExtraModulesTests: JSBridgeTests {

    func testUnderscore() {
        let inputArray = [1, 2, 3]
        self.context.evaluateScript("var _ = require('underscore');")
        self.context.globalObject.setValue(inputArray, forProperty: "inputArray")
        self.context.evaluateScript("var outputArray = _.map(inputArray, function(i) { return i*i; });")
        let outputArray = self.context.globalObject.valueForProperty("outputArray").toArray() as! [Int]
        XCTAssertEqual(inputArray.map { $0*$0 }, outputArray)
    }

    func testQ() {
        self.context.evaluateScript("var Q = require('q');")
        self.context.evaluateScript("Q.fcall(function() { return 10; }).then(function(v) { global.result = v; });")

        // Wait for a while ... (since Promise is asynchronous)
        let expectation = self.expectationWithDescription("wait")
        after(0.1) {
            XCTAssertEqual(self.context.globalObject.valueForProperty("result").toNumber(), 10)
            expectation.fulfill()
        }
    }
    
}
