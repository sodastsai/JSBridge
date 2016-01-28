//
//  TCJSConsole.h
//  JSBridge
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

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TCJSOutputConsole <NSObject>

- (void)writeConsoleMessage:(NSString *)message level:(NSString *)level forJavaScriptContext:(JSContext *)context;

@end

@protocol TCJSConsole <JSExport>

- (void)debug;
- (void)log;
- (void)info;
- (void)error;
- (void)warn;

@end

@interface TCJSConsole : NSObject <TCJSConsole>

@property (nonatomic, weak, nullable) id<TCJSOutputConsole> outputConsole;

@end

NS_ASSUME_NONNULL_END
