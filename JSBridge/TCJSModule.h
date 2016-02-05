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

// Ref: http://fredkschott.com/post/2014/06/require-and-the-module-system/

NS_ASSUME_NONNULL_BEGIN

@class TCJSModule;

@protocol TCJSModule <JSExport>

@property (nonatomic, strong, readonly) NSString *filename;
@property (nonatomic, assign, readonly, getter=isLoaded) BOOL loaded;
@property (nonatomic, strong, readonly) NSMutableArray<NSString *> *paths;
@property (nonatomic, nullable, readwrite) JSValue *exports;  // Delegate to JSManagedValue
@property (nonatomic, nullable, readwrite) JSValue *require;  // Delegate to JSManagedValue

@end

typedef BOOL(^TCJSModuleLoader)(TCJSModule *module, NSString *filepath, JSContext *context);

@interface TCJSModule : NSObject <TCJSModule, TCJSJavaScriptContextExtension>

+ (void)registerGlobalModuleNamed:(NSString *)globalModuleName withBlock:(TCJSModule *(^)(JSContext *context))block;

+ (nullable TCJSModule *)mainModuleOfContext:(JSContext *)context;

- (instancetype)initWithContext:(nullable JSContext *)context NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithExports:(JSValue *)exports context:(nullable JSContext *)context;
- (nullable instancetype)initWithContentOfFile:(NSString *)filepath context:(nullable JSContext *)context;

@end

@interface TCJSRequire : NSObject

+ (JSValue *)globalRequireFunctionInContext:(JSContext *)context;
+ (JSValue *)createNewRequireFunctionForModule:(TCJSModule *)module context:(JSContext *)context;

+ (void)registerModuleLoader:(nullable TCJSModuleLoader)moduleLoader
                forExtension:(NSString *)extension
                     context:(JSContext *)context;
+ (NSDictionary<NSString *, TCJSModuleLoader> *)registeredModuleLoadersInContext:(JSContext *)context;

+ (NSDictionary<NSString *, TCJSModule *> *)loadedModulesInContext:(JSContext *)context;

+ (TCJSModule *)loadModuleByPath:(NSString *)jsPath
                    parentModule:(nullable TCJSModule *)parentModule
                         context:(JSContext *)context;
+ (nullable NSString *)resolve:(NSString *)jsPath
                  parentModule:(nullable TCJSModule *)module
                        loader:(TCJSModuleLoader _Nullable __autoreleasing *_Nullable)outLoader
                       context:(JSContext *)context;

@end

NS_ASSUME_NONNULL_END
