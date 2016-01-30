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

    var temporaryDirPath: String!
    
    override func setUp() {
        super.setUp()

        self.temporaryDirPath = NSFileManager.defaultManager().pathOfUniqueTemporaryFolder
        if !NSFileManager.defaultManager().fileExistsAtPath(self.temporaryDirPath) {
            try! NSFileManager.defaultManager().createDirectoryAtPath(self.temporaryDirPath,
                withIntermediateDirectories: true, attributes: nil)
        }

        self.context.evaluateScript("var fs = require('fs');")
        TCJSFileSystem.defaultFileSystem().delegate = self
    }

    override func tearDown() {
        super.tearDown()
        self.temporaryDirPath = nil
    }

    // MARK: - File System Delegate

    func context(context: JSContext, hasPermissionToReadFileAtPath path: String) -> Bool {
        let pathString = path as NSString
        return path == self.bundle.bundlePath ||
            pathString.isSubpathOfPath(self.bundle.bundlePath) || pathString.isSubpathOfPath(self.temporaryDirPath)
    }

    func context(context: JSContext, hasPermissionToWriteFileAtPath path: String) -> Bool {
        return (path as NSString).isSubpathOfPath(self.temporaryDirPath)
    }

    func context(context: JSContext, hasPermissionToDeleteFileAtPath path: String) -> Bool {
        return (path as NSString).isSubpathOfPath(self.temporaryDirPath)
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

    func testWriteFile() {
        let dataBuffer = TCJSDataBuffer(data: NSData(hexString: "01027fff")!.mutableCopy() as! NSMutableData)
        self.context.globalObject.setValue(dataBuffer, forProperty: "dataBuffer")

        let filePath = (self.temporaryDirPath as NSString).stringByAppendingPathComponent("data")

        let expectation = self.expectationWithDescription("read file")
        let block: @convention(block) (JSValue) -> Void = { (errorValue) in
            XCTAssertTrue(errorValue.isNull)
            XCTAssertEqual(NSData(contentsOfFile: filePath), NSData(hexString: "01027fff"))
            expectation.fulfill()
        }
        self.context.globalObject.setValue(unsafeBitCast(block, AnyObject.self), forProperty: "block")

        self.context.evaluateScript("fs.writeFile('\(filePath)', dataBuffer, function(err) { block(err); });")
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
