//
//  TCJSDataBuffer.h
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
#import <TCJSBridge/TCJSJavaScriptContext.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TCJSDataBuffer <JSExport>

+ (instancetype)create;

@property (nonatomic, readwrite) NSUInteger length;
- (JSValue *)byte;

@property (nonatomic, readonly) NSString *hexDigest;

@end

@interface TCJSDataBuffer : NSObject <TCJSDataBuffer, TCJSJavaScriptContextExtension>

@property (nonatomic, strong, readonly) NSMutableData *data;

- (instancetype)initWithLength:(NSUInteger)length NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
