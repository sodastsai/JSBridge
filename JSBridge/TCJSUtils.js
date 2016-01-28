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

'use strict';

var objectToString = exports.objectToString = function(obj) {
    return Object.prototype.toString.call(obj);
}

exports.isRegExp = function(obj) {
    return objectToString(obj) === '[object RegExp]';
};

exports.isArray = function(obj) {
    return objectToString(obj) === '[object Array]';
};

exports.isDate = function(obj) {
    return objectToString(obj) === '[object Date]';
};

exports.isError = function(obj) {
    return objectToString(obj) === '[object Error]';
};
