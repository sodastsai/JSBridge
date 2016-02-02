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

@class TCJSModule;

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

+ (JSValue *)extends:(JSValue *)object withObjects:(NSArray<JSValue *> *)objects context:(JSContext *)context;

+ (void)defineProperty:(NSString *)property
            enumerable:(BOOL)enumerable
          configurable:(BOOL)configurable
              writable:(BOOL)writable
                 value:(nullable id)value
                getter:(nullable id _Nullable(^)(void))getter
                setter:(nullable void(^)(id _Nullable))setter
              forValue:(JSValue *)jsValue;

+ (JSValue *)inherits:(JSValue *)constructor
 withSuperConstructor:(JSValue *)superConstructor
              context:(JSContext *)context;

+ (void)defineProperty:(NSString *)property
              forValue:(JSValue *)value
 withNativeObjectNamed:(NSString *)nativeObjectName
               keyPath:(NSString *)keyPath
              readonly:(BOOL)readonly;

+ (void)defineReadonlyProperty:(NSString *)property forJSValue:(JSValue *)jsValue withValue:(id)value;

@end

@interface TCJSConstructorBuilder : NSObject

+ (instancetype)constructorBuilderWithName:(NSString *)name;
- (instancetype)initWithName:(NSString *)name NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)addProperty:(nullable NSString *)property argumentName:(NSString *)argument passToSuper:(BOOL)toSuper;

@property (nonatomic, readonly) NSString *script;
- (JSValue *)buildWithContext:(JSContext *)context;
- (JSValue *)buildWithModule:(TCJSModule *)module context:(JSContext *)context;

@end

NS_ASSUME_NONNULL_END
