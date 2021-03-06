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

var tests2 = require('RequireTests2.js');

module.exports.answer = 42;

var garbage = 43;
global.overrided = 44;

exports.name = "Tickle";

module.exports.twentyFive = tests2.squareAdd(3, 4);

global.loadCount++;

module.exports.requireFuncCmp = require === global.require;
module.exports.moduleRequireFuncCmp = require === module.require;
module.exports.resolveFuncCmp = require.resolve === global.require.resolve;
module.exports.requireCacheCmp = require.cache === global.require.cache;
module.exports.requireExtensionsCmp = require.extensions === global.require.extensions;
