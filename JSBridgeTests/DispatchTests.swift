//
//  DispatchTests.swift
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

class DispatchTests: JSBridgeTests {
    
    override func setUp() {
        super.setUp()
        self.context.evaluateScript("var dispatch = require('dispatch');")
    }

    func testAsyncIOQueue() {
        let expectation = self.expectationWithDescription("wait")
        let block: @convention(block) () -> Void = {
            XCTAssertFalse(NSThread.isMainThread())
            expectation.fulfill()
        }
        self.context.globalObject.setValue(unsafeBitCast(block, AnyObject.self), forProperty: "block")
        self.context.evaluateScript("dispatch.async(dispatch.ioQueue, function() { block(); });")
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
}
