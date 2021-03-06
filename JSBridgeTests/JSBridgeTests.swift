//
//  JSBridgeTests.swift
//  JSBridgeTests
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

class JSBridgeTests: XCTestCase {
    var context: JSContext!

    lazy var bundle: NSBundle = { [unowned self] in
        return NSBundle(forClass: self.dynamicType)
        }()

    override func setUp() {
        super.setUp()
        self.context = JSContext()
        TCJSJavaScriptContextSetupContext(self.context)
        self.context.name = "JSBridge UnitTest for \(self.name)"
    }

    override func tearDown() {
        self.context = nil
        super.tearDown()
    }

    func after(timeInterval: NSTimeInterval, block: () -> Void) {
        let expectation = self.expectationWithDescription("after")
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(timeInterval*Double(NSEC_PER_SEC))),
            dispatch_get_main_queue()) {
                block()
                expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
}
