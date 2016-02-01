//
//  TCJSUtils.h
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

@protocol TCJSUtilEnumerate <NSObject>

+ (NSArray<NSString *> *)enumerableJSProperties;

@end

@interface TCJSUtil : NSObject

+ (NSString *)format;
+ (NSString *)inspect:(JSValue *)object;

+ (NSString *)toString:(JSValue *)obj context:(JSContext *)context;
+ (BOOL)isFunction:(JSValue *)obj context:(JSContext *)context;
+ (BOOL)isArray:(JSValue *)obj context:(JSContext *)context;
+ (BOOL)isDate:(JSValue *)obj context:(JSContext *)context;
+ (BOOL)isError:(JSValue *)obj context:(JSContext *)context;
+ (BOOL)isRegExp:(JSValue *)obj context:(JSContext *)context;

+ (NSArray<NSString *> *)arrayWithPropertiesOfValue:(JSValue *)value context:(JSContext *)context;

@end

NS_ASSUME_NONNULL_END
