//
//  ApplicationTests.swift
//  JSBridgeApp
//
//  Created by sodas on 1/28/16.
//  Copyright © 2016 JSBridge. All rights reserved.
//

import XCTest
import BenzeneFoundation

class ApplicationTests: JSBridgeTests {

    func testVersion() {
        XCTAssertEqual(self.context.evaluateScript("application.version;").toString(),
            NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as? String)
    }

    func testBuild() {
        XCTAssertEqual(self.context.evaluateScript("application.build;").toString(),
            NSBundle.mainBundle().infoDictionary!["CFBundleVersion"] as? String)
    }

    func testIdentifier() {
        XCTAssertEqual(self.context.evaluateScript("application.identifier;").toString(),
            NSBundle.mainBundle().bundleIdentifier)
    }

    func testLocale() {
        XCTAssertEqual(self.context.evaluateScript("application.locale;").toString(),
            NSLocale.currentLocale().localeIdentifier)
    }

    func testPreferredLanguages() {
        XCTAssertEqual(self.context.evaluateScript("application.preferredLanguages;").toArray() as! [String],
            NSLocale.preferredLanguages())
    }

}

class SystemTests: JSBridgeTests {

    func testVersion() {
        XCTAssertEqual(self.context.evaluateScript("system.version;").toString(),
            UIDevice.currentDevice().systemVersion)
    }

    func testName() {
        XCTAssertEqual(self.context.evaluateScript("system.name;").toString(),
            UIDevice.currentDevice().systemName)
    }

    func testModel() {
        XCTAssertEqual(self.context.evaluateScript("system.model;").toString(),
            UIDevice.currentDevice().modelIdentifier)
    }

}
