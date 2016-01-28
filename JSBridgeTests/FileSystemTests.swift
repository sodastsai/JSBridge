//
//  FileSystemTests.swift
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
import BenzeneFoundation

protocol FileSystemTestsBody {
    func testExists()
}

class FileSystemTests: JSBridgeTests, FileSystemTestsBody, TCJSFileSystemDelegate {
    
    override func setUp() {
        super.setUp()
        self.context.evaluateScript("var fs = require('fs');")
        TCJSFileSystem.defaultFileSystem().delegate = self
    }

    // MARK: - File System Delegate

    func context(context: JSContext, hasPermissionToReadFileAtPath path: String) -> Bool {
        return (path as NSString).isSubpathOfPath(self.bundle.bundlePath)
    }

    // MARK: - Test Body

    func testExists() {
        XCTAssertFalse(self.context.evaluateScript("fs.exists('/');").toBool())

        let requireJSPath = (self.bundle.bundlePath as NSString).stringByAppendingPathComponent("RequireTests.js")
        let require1JSPath = (self.bundle.bundlePath as NSString).stringByAppendingPathComponent("RequireTestsABC.js")
        XCTAssertTrue(self.context.evaluateScript("fs.exists('\(requireJSPath)');").toBool())
        XCTAssertFalse(self.context.evaluateScript("fs.exists('\(require1JSPath)');").toBool())
    }

}

class FileSystemWithoutDelegateTests: JSBridgeTests, FileSystemTestsBody {

    override func setUp() {
        super.setUp()
        self.context.evaluateScript("var fs = require('fs');")
    }

    func testExists() {
        XCTAssertFalse(self.context.evaluateScript("fs.exists('/');").toBool())
    }

}
