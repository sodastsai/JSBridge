//
//  TCJSDispatch.h
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

extern NSString *const TCJSDispatchManagerUIQueueName;
extern NSString *const TCJSDispatchManagerIOQueueName;
extern NSString *const TCJSDispatchManagerMainQueueName;
extern NSString *const TCJSDispatchManagerBackgroundQueueName;

@interface TCJSDispatchManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, assign) BOOL shouldExposeUIQueue;

// NOTE: return value of the block would be arguments of the callback
+ (void)asyncExecute:(NSArray *_Nullable (^)(JSContext *))block callback:(nullable JSValue *)callback;

@end

NS_ASSUME_NONNULL_END
