//
//  FileSystemTests.swift
//  JSBridgeApp
//
//  Created by sodas on 1/28/16.
//  Copyright © 2016 JSBridge. All rights reserved.
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
