//
//  DispatchTests.swift
//  JSBridgeApp
//
//  Created by sodas on 1/29/16.
//  Copyright © 2016 JSBridge. All rights reserved.
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
