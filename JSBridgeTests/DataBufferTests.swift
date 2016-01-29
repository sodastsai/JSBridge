//
//  DataBufferTests.swift
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

class DataBufferTests: JSBridgeTests {
    
    func testCreate() {
        let dataBuffer1 = self.context.evaluateScript("DataBuffer.create();")
            .toObjectOfClass(TCJSDataBuffer) as! TCJSDataBuffer
        let dataBuffer2 = self.context.evaluateScript("DataBuffer.create(20);")
            .toObjectOfClass(TCJSDataBuffer) as! TCJSDataBuffer

        XCTAssertEqual(dataBuffer1.length, 0)
        XCTAssertEqual(dataBuffer2.length, 20)
    }

    func testFromHexString() {
        let dataBuffer = self.context.evaluateScript("DataBuffer.fromHexString(\"00ffcc3e\");")
            .toObjectOfClass(TCJSDataBuffer) as! TCJSDataBuffer
        XCTAssertEqual(dataBuffer.data, NSData(bytes: [0x00, 0xff, 0xcc, 0x3e] as [UInt8], length: 4))
        XCTAssertEqual(dataBuffer.length, 4)
    }

    func testFromByteArray() {
        let dataBuffer = self.context.evaluateScript("DataBuffer.fromByteArray([1, 2, 127, 255]);")
            .toObjectOfClass(TCJSDataBuffer) as! TCJSDataBuffer
        XCTAssertEqual(dataBuffer.data, NSData(bytes: [0x01, 0x02, 0x7f, 0xff] as [UInt8], length: 4))
        XCTAssertEqual(dataBuffer.length, 4)
    }

    func testSubDataBuffer() {
        var dataBuffer = self.context.evaluateScript("DataBuffer.fromByteArray([1, 2, 127, 255]).subDataBuffer(0, 2);")
            .toObjectOfClass(TCJSDataBuffer) as! TCJSDataBuffer
        XCTAssertEqual(dataBuffer.data, NSData(bytes: [0x01, 0x02] as [UInt8], length: 2))
        XCTAssertEqual(dataBuffer.length, 2)

        dataBuffer = self.context.evaluateScript("DataBuffer.fromByteArray([1, 2, 127, 255]).subDataBuffer(1, 3);")
            .toObjectOfClass(TCJSDataBuffer) as! TCJSDataBuffer
        XCTAssertEqual(dataBuffer.data, NSData(bytes: [0x02, 0x7f, 0xff] as [UInt8], length: 3))
        XCTAssertEqual(dataBuffer.length, 3)

        dataBuffer = self.context.evaluateScript("DataBuffer.fromByteArray([1, 2, 127, 255]).subDataBuffer(2, 0);")
            .toObjectOfClass(TCJSDataBuffer) as! TCJSDataBuffer
        XCTAssertEqual(dataBuffer.data, NSData())
        XCTAssertEqual(dataBuffer.length, 0)
    }

    func testCopyAsNewDataBuffer() {
        let dataBuffer1 = self.context.evaluateScript("var d1 = DataBuffer.fromByteArray([1, 2, 127, 255]); d1;")
            .toObjectOfClass(TCJSDataBuffer) as! TCJSDataBuffer
        let dataBuffer2 = self.context.evaluateScript("var d2 = d1.copyAsNewDataBuffer(); d2;")
            .toObjectOfClass(TCJSDataBuffer) as! TCJSDataBuffer
        XCTAssertEqual(dataBuffer1.data, dataBuffer2.data)
        XCTAssertFalse(dataBuffer1 === dataBuffer2)
        XCTAssertFalse(self.context.evaluateScript("d2 == d1;").toBool())
    }

    func testLength() {
        let dataBuffer = TCJSDataBuffer(data: NSMutableData(bytes: [0x01, 0x02] as [UInt8], length: 2))
        self.context.globalObject.setValue(dataBuffer, forProperty: "dataBuffer")
        XCTAssertEqual(self.context.evaluateScript("dataBuffer.length;").toNumber(), 2)
    }

    func testHexString() {
        let dataBuffer = TCJSDataBuffer(data: NSMutableData(bytes: [0x01, 0x68, 0xfc] as [UInt8], length: 3))
        self.context.globalObject.setValue(dataBuffer, forProperty: "dataBuffer")
        XCTAssertEqual(self.context.evaluateScript("dataBuffer.hexString;").toString(), "0168fc")
    }

    func testAppend() {
        let dataBuffer1 = TCJSDataBuffer(data: NSMutableData(bytes: [0x01, 0x02] as [UInt8], length: 2))
        let dataBuffer2 = TCJSDataBuffer(data: NSMutableData(bytes: [0x07, 0x68, 0xfc] as [UInt8], length: 3))
        self.context.globalObject.setValue(dataBuffer1, forProperty: "dataBuffer1")
        self.context.globalObject.setValue(dataBuffer2, forProperty: "dataBuffer2")
        self.context.evaluateScript("dataBuffer1.append(dataBuffer2);")
        XCTAssertEqual(dataBuffer1.length, 5)
        XCTAssertEqual(dataBuffer1.data, NSMutableData(bytes: [0x01, 0x02, 0x07, 0x68, 0xfc] as [UInt8], length: 5))
    }

    func testEqual() {
        let dataBuffer1 = TCJSDataBuffer(data: NSMutableData(bytes: [0x01, 0x02] as [UInt8], length: 2))
        let dataBuffer2 = TCJSDataBuffer(data: NSMutableData(bytes: [0x01, 0x03] as [UInt8], length: 2))
        let dataBuffer3 = TCJSDataBuffer(data: NSMutableData(bytes: [0x01, 0x02] as [UInt8], length: 2))
        self.context.globalObject.setValue(dataBuffer1, forProperty: "dataBuffer1")
        self.context.globalObject.setValue(dataBuffer2, forProperty: "dataBuffer2")
        self.context.globalObject.setValue(dataBuffer3, forProperty: "dataBuffer3")
        XCTAssertFalse(self.context.evaluateScript("dataBuffer1.equal(dataBuffer2);").toBool())
        XCTAssertTrue(self.context.evaluateScript("dataBuffer1.equal(dataBuffer3);").toBool())
    }

    func testByte0() {
        XCTAssertEqual(self.context.evaluateScript("DataBuffer.fromHexString('0102').byte();").toArray() as! [Int],
            [1, 2])
    }

    func testByte1() {
        let dataBuffer = TCJSDataBuffer(data: NSMutableData(bytes: [0x01, 0x02] as [UInt8], length: 2))
        self.context.globalObject.setValue(dataBuffer, forProperty: "dataBuffer")
        XCTAssertEqual(self.context.evaluateScript("dataBuffer.byte(0);").toNumber(), 1)
    }

    func testByte2() {
        let dataBuffer = TCJSDataBuffer(data: NSMutableData(bytes: [0x01, 0x02] as [UInt8], length: 2))
        self.context.globalObject.setValue(dataBuffer, forProperty: "dataBuffer")
        self.context.evaluateScript("dataBuffer.byte(0, 127);")
        XCTAssertEqual(dataBuffer.data, NSMutableData(bytes: [0x7f, 0x02] as [UInt8], length: 2))
    }

    func testDelete() {
        let data = NSMutableData(bytes: [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07] as [UInt8], length: 7)
        let dataBuffer = TCJSDataBuffer(data: data)
        self.context.globalObject.setValue(dataBuffer, forProperty: "dataBuffer")
        self.context.evaluateScript("dataBuffer.delete(2, 2);")
        XCTAssertEqual(dataBuffer.data, NSMutableData(bytes: [0x01, 0x02, 0x05, 0x06, 0x07] as [UInt8], length: 5))
    }

    func testInsert() {
        let dataBuffer1 = TCJSDataBuffer(data: NSMutableData(bytes: [0x01, 0x04, 0x05, 0x06] as [UInt8], length: 4))
        let dataBuffer2 = TCJSDataBuffer(data: NSMutableData(bytes: [0x02, 0x03] as [UInt8], length: 2))
        self.context.globalObject.setValue(dataBuffer1, forProperty: "dataBuffer1")
        self.context.globalObject.setValue(dataBuffer2, forProperty: "dataBuffer2")
        self.context.evaluateScript("dataBuffer1.insert(dataBuffer2, 1);")
        XCTAssertEqual(dataBuffer1.data, NSMutableData(bytes: [0x01, 0x02, 0x03, 0x04, 0x05, 0x06] as [UInt8],
            length: 6))
    }

}
