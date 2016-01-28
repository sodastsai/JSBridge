//
//  ApplicationTests.swift
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
