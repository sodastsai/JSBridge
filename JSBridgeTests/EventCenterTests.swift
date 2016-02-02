//
//  EventCenterTests.swift
//  JSBridgeApp
//
//  Created by sodas on 2/3/16.
//  Copyright © 2016 JSBridge. All rights reserved.
//

import XCTest

class Object: NSObject {
}

class EventCenterTests: JSBridgeTests {
    
    override func setUp() {
        super.setUp()
        self.context.evaluateScript("var events = require('events');")
    }

    func testEventCenter() {
        let object = Object()
        let notificationName = "EventCenterTestNotification"
        let notification = NSNotification(name: notificationName, object: object, userInfo: ["answer": 42])

        var blockCalled = false
        let block: @convention(block) (name: String, object: AnyObject, userInfo: [NSString: AnyObject]) -> Void = {
            (name: String, _object: AnyObject, userInfo: [NSString: AnyObject]) in

            XCTAssertEqual(name, notificationName)
            XCTAssertEqual(_object as? Object, object)
            XCTAssertEqual(userInfo["answer"] as? Int, 42)
            blockCalled = true
        }
        self.context.globalObject.setValue(unsafeBitCast(block, AnyObject.self), forProperty: "block")
        self.context.evaluateScript("var o = events.EventCenter.on('\(notificationName)', block)")

        NSNotificationQueue.defaultQueue().enqueueNotification(notification, postingStyle: .PostNow)
        XCTAssertTrue(blockCalled)
        self.context.evaluateScript("events.EventCenter.off(o)")
    }
    
}
