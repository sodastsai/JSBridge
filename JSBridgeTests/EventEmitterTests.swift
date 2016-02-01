//
//  EventEmitterTests.swift
//  JSBridgeApp
//
//  Created by sodas on 1/30/16.
//  Copyright © 2016 JSBridge. All rights reserved.
//

import XCTest

class EventEmitterTests: JSBridgeTests {
    
    override func setUp() {
        super.setUp()
        self.context.evaluateScript("var events = require('events');")
    }

    func testOn() {
        var callCount = 0
        let block: @convention(block) (Int) -> Void = { (answer: Int) in
            XCTAssertEqual(answer, 42)
            callCount += 1
        }
        self.context.globalObject.setValue(unsafeBitCast(block, AnyObject.self), forProperty: "block")
        self.context.evaluateScript("var emitter = new events.EventEmitter();")
        self.context.evaluateScript("emitter.on('go', block);")
        self.context.evaluateScript("emitter.emit('go', 42);")
        self.context.evaluateScript("emitter.emit('go', 42);")
        XCTAssertEqual(callCount, 2)
    }

    func testAddEventListener() {
        let block: @convention(block) (Int) -> Void = { (answer: Int) in
            XCTAssertEqual(answer, 42)
        }
        self.context.globalObject.setValue(unsafeBitCast(block, AnyObject.self), forProperty: "block")
        self.context.evaluateScript("var emitter = new events.EventEmitter();")
        self.context.evaluateScript("emitter.addEventListener('go', block);")
        self.context.evaluateScript("emitter.emit('go', 42);")
    }

    func testAddEventListenerMultipleTimes() {
        var callCount = 0
        let block: @convention(block) (Int) -> Void = { (answer: Int) in
            XCTAssertEqual(answer, 42)
            callCount += 1
        }
        self.context.globalObject.setValue(unsafeBitCast(block, AnyObject.self), forProperty: "block")
        self.context.evaluateScript("var emitter = new events.EventEmitter();")
        self.context.evaluateScript("emitter.addEventListener('go', block);")
        self.context.evaluateScript("emitter.addEventListener('go', block);")
        self.context.evaluateScript("emitter.emit('go', 42);")
        XCTAssertEqual(callCount, 2)
    }

    func testOnce() {
        var callCount = 0
        let block: @convention(block) (Int) -> Void = { (answer: Int) in
            XCTAssertEqual(answer, 42)
            callCount += 1
        }
        self.context.globalObject.setValue(unsafeBitCast(block, AnyObject.self), forProperty: "block")
        self.context.evaluateScript("var emitter = new events.EventEmitter();")
        self.context.evaluateScript("emitter.once('go', block);")
        self.context.evaluateScript("emitter.emit('go', 42);")
        self.context.evaluateScript("emitter.emit('go', 42);")
        XCTAssertEqual(callCount, 1)
    }

    func testRemoveEventListener() {
        var callCount = 0
        let block: @convention(block) (Int) -> Void = { (answer: Int) in
            XCTAssertEqual(answer, 42)
            callCount += 1
        }
        self.context.globalObject.setValue(unsafeBitCast(block, AnyObject.self), forProperty: "block")
        self.context.evaluateScript("var emitter = new events.EventEmitter();")
        self.context.evaluateScript("emitter.on('go', block);")
        self.context.evaluateScript("emitter.on('go', block);")
        self.context.evaluateScript("emitter.removeEventListener('go', block);")
        self.context.evaluateScript("emitter.emit('go', 42);")
        XCTAssertEqual(callCount, 1)
    }

    func testInheritence() {
        self.context.evaluateScript("var util = require('util');")
        self.context.evaluateScript("function MyEventEmitter() { events.EventEmitter.apply(this, arguments); }")
        self.context.evaluateScript("util.inherits(MyEventEmitter, events.EventEmitter);")
        self.context.evaluateScript("var emitter = new MyEventEmitter();")

        XCTAssertTrue(self.context.evaluateScript("emitter instanceof events.EventEmitter;").toBool())
        let block: @convention(block) (Int) -> Void = { (answer: Int) in
            XCTAssertEqual(answer, 42)
        }
        self.context.globalObject.setValue(unsafeBitCast(block, AnyObject.self), forProperty: "block")
        self.context.evaluateScript("emitter.on('go', block);")
        self.context.evaluateScript("emitter.emit('go', 42);")
    }

}