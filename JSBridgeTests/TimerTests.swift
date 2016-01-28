//
//  TimerTests.swift
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

class TimerTests: JSBridgeTests {

    func after(timeInterval: NSTimeInterval, block: () -> Void) {
        let expectation = self.expectationWithDescription("after")
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(timeInterval*Double(NSEC_PER_SEC))),
            dispatch_get_main_queue()) {
                block()
                expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testSetTimeout() {
        self.context.evaluateScript("var t0 = new Date(), t1 = undefined; setTimeout(function() { t1 = new Date(); }, 1000);")
        after(1.25) {
            let t0 = self.context.globalObject.valueForProperty("t0").toDate()
            let t1 = self.context.globalObject.valueForProperty("t1").toDate()
            XCTAssertGreaterThanOrEqual(t1.timeIntervalSinceDate(t0), 1.0)
        }
    }

    func testSetTimeoutWithArguments() {
        self.context.evaluateScript("setTimeout(function(a, b) { global.result = a + b; }, 700, 4, 5);")
        after(1) {
            XCTAssertEqual(self.context.globalObject.valueForProperty("result").toNumber(), 9)
        }
    }

    func testClearTimeout() {
        self.context.evaluateScript("var r = undefined; var t = setTimeout(function() { r = new Date(); }, 800);" +
            "setTimeout(function() { clearTimeout(t); t = undefined; }, 400);")
        after(1.0) {
            XCTAssertTrue(self.context.globalObject.valueForProperty("r").isUndefined)
            XCTAssertTrue(self.context.globalObject.valueForProperty("t").isUndefined)
        }
    }

    func testSetInterval() {
        self.context.evaluateScript("var r0 = 0; setInterval(function() { r0 += 1; }, 500);")
        after(1.75) {
            XCTAssertEqual(self.context.globalObject.valueForProperty("r0").toNumber(), 3)
        }

        self.context.evaluateScript("var r1 = 1; setInterval(function(a) { r1 *= a; }, 500, 2);")
        after(1.75) {
            XCTAssertEqual(self.context.globalObject.valueForProperty("r1").toNumber(), 8)
        }
    }

    func testClearInterval() {
        self.context.evaluateScript("var r0 = 0; var ti = setInterval(function() { r0 += 1; }, 500); " +
            "setTimeout(function() { clearInterval(ti); ti = undefined; }, 1250);")
        after(1.75) {
            XCTAssertEqual(self.context.globalObject.valueForProperty("r0").toNumber(), 2)
        }
    }
    
}
