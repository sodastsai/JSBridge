//
//  ViewController.swift
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

import UIKit
import TCJSBridge
import JavaScriptCore

class ViewController: UIViewController {

    var context: JSContext!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.loadContext()
    }

    @IBAction func reset(sender: UIButton) {
        TCJSJavaScriptContextDeactivateContext(self.context)
        self.context = nil

        self.loadContext()
    }

    func loadContext () {
        if self.context == nil {
            self.context = JSContext()
            TCJSJavaScriptContextSetupContext(self.context)
        }
    }

}

