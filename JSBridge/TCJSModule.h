//
//  TCJSModule.h
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

@class TCJSModule;

@protocol TCJSModule <JSExport>

@property (nonatomic, strong, readonly) NSString *filename;
@property (nonatomic, assign, readonly, getter=isLoaded) BOOL loaded;
@property (nonatomic, strong, readwrite) JSValue *exports;

@property (nonatomic, strong, readonly) NSMutableArray<NSString *> *paths;
- (nullable JSValue *)require:(NSString *)jsPath;

@end

@interface TCJSModule : NSObject <TCJSModule, TCJSJavaScriptContextExtension>

+ (void)registerGlobalModuleNamed:(NSString *)globalModuleName withBlock:(TCJSModule *(^)(void))block;

+ (nullable instancetype)mainModule;

- (nullable instancetype)initWithScriptContentsOfFile:(nullable NSString *)path;
- (nullable instancetype)initWithScriptContentsOfFile:(nullable NSString *)path
                                            loadPaths:(nullable NSArray<NSString *> *)loadPaths;
- (instancetype)initWithScript:(nullable NSString *)script
                    sourceFile:(nullable NSString *)path
                     loadPaths:(nullable NSArray<NSString *> *)loadPaths NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
