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
        return path == self.bundle.bundlePath || (path as NSString).isSubpathOfPath(self.bundle.bundlePath)
    }

    // MARK: - Test Body

    func testExistsSync() {
        XCTAssertFalse(self.context.evaluateScript("fs.existsSync('/');").toBool())

        let requireJSPath = (self.bundle.bundlePath as NSString).stringByAppendingPathComponent("RequireTests.js")
        let require1JSPath = (self.bundle.bundlePath as NSString).stringByAppendingPathComponent("RequireTestsABC.js")
        XCTAssertTrue(self.context.evaluateScript("fs.existsSync('\(requireJSPath)');").toBool())
        XCTAssertFalse(self.context.evaluateScript("fs.existsSync('\(require1JSPath)');").toBool())
    }

    func testExists() {
        let requireJS1Path = (self.bundle.bundlePath as NSString).stringByAppendingPathComponent("RequireTests.js")
        let requireJS2Path = (self.bundle.bundlePath as NSString).stringByAppendingPathComponent("RequireTestsABC.js")
        self.context.evaluateScript("var exists1 = false, exists2 = false;")
        self.context.evaluateScript("fs.exists('\(requireJS1Path)', function(exists) { exists1 = exists; });")
        self.context.evaluateScript("fs.exists('\(requireJS2Path)', function(exists) { exists2 = exists; });")
        after(0.25) {
            XCTAssertTrue(self.context.globalObject.valueForProperty("exists1").toBool())
            XCTAssertFalse(self.context.globalObject.valueForProperty("exists2").toBool())
        }
    }

    func testIsDirectory() {
        self.context.evaluateScript("var isDir = false;")
        self.context.evaluateScript("fs.isDirectory('\(self.bundle.bundlePath)', function(i) { isDir = i; });")
        after(0.25) {
            XCTAssertTrue(self.context.globalObject.valueForProperty("isDir").toBool())
        }
        XCTAssertTrue(self.context.evaluateScript("fs.isDirectorySync('\(self.bundle.bundlePath)');").toBool())

        let requireJSPath = (self.bundle.bundlePath as NSString).stringByAppendingPathComponent("RequireTests.js")
        XCTAssertFalse(self.context.evaluateScript("fs.isDirectorySync('\(requireJSPath)');").toBool())
    }

    func testReadFile() {
        let expectation = self.expectationWithDescription("read file")
        let block: @convention(block) (JSValue, JSValue) -> Void = { (dataBufferValue, errorValue) in
            XCTAssertTrue(errorValue.isNull)
            let dataBuffer = dataBufferValue.toObjectOfClass(TCJSDataBuffer) as! TCJSDataBuffer
            XCTAssertEqual(dataBuffer.data,
                ("JSBridge" as NSString).dataUsingEncoding(NSUTF8StringEncoding)?.mutableCopy() as? NSMutableData)
            expectation.fulfill()
        }
        self.context.globalObject.setValue(unsafeBitCast(block, AnyObject.self), forProperty: "block")
        let txtPath = self.bundle.pathForResource("jsbridge", ofType: "txt")!
        self.context.evaluateScript("fs.readFile('\(txtPath)', function(data, err) { block(data, err); });")
        self.waitForExpectationsWithTimeout(0.5, handler: nil)
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
