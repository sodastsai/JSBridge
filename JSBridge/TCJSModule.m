//
//  TCJSModule.m
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

#import "TCJSModule.h"
#import "TCJSUtils.h"
#import <BenzeneFoundation/BenzeneFoundation.h>

@interface TCJSModule ()

@property (nonatomic, strong) NSString *moduleID;
@property (nonatomic, strong, readwrite) NSString *filename;
@property (nonatomic, assign, readwrite, getter=isLoaded) BOOL loaded;
@property (nonatomic, strong, readwrite) NSMutableArray<NSString *> *paths;

@property (nonatomic, strong) JSManagedValue *managedExports;

+ (NSMutableDictionary<NSString *, TCJSModule *(^)(JSContext *)> *)registeredGlobalModules;

@end

@interface TCJSRequire ()

+ (void)setModule:(nullable TCJSModule *)module asLoadedForPath:(NSString *)path context:(JSContext *)context;

@end

NSString *const TCJSRequireExtensionsKey = @"extensions";
NSString *const TCJSRequireCacheKey = @"cache";

@implementation TCJSRequire

+ (void)loadExtensionForJSContext:(JSContext *)context {
    [self globalRequireFunctionInContext:context];
}

+ (void)registerModuleLoader:(nullable TCJSModuleLoader)moduleLoader
                forExtension:(NSString *)pathExtension
                     context:(JSContext *)context {
    JSValue *extension = [self globalRequireFunctionInContext:context][TCJSRequireExtensionsKey];
    if (moduleLoader) {
        extension[pathExtension] = moduleLoader;
    } else {
        [extension deleteProperty:pathExtension];
    }
}

+ (NSDictionary<NSString *, TCJSModuleLoader> *)registeredModuleLoadersInContext:(JSContext *)context {
    return [self globalRequireFunctionInContext:context][TCJSRequireExtensionsKey].toDictionary;
}

+ (void)setModule:(nullable TCJSModule *)module asLoadedForPath:(NSString *)path context:(JSContext *)context {
    JSValue *cache = [self globalRequireFunctionInContext:context][TCJSRequireCacheKey];
    if (module) {
        cache[path] = module;
    } else {
        [cache deleteProperty:path];
    }
}

+ (NSDictionary<NSString *, TCJSModule *> *)loadedModulesInContext:(JSContext *)context {
    return [self globalRequireFunctionInContext:context][TCJSRequireCacheKey].toDictionary;
}

+ (nullable NSString *)resolve:(NSString *)jsPath
                  parentModule:(nullable TCJSModule *)parentModule
                        loader:(__autoreleasing TCJSModuleLoader  _Nullable *)outLoader
                       context:(nonnull JSContext *)context {
    parentModule = parentModule ?: [TCJSModule mainModuleOfContext:context];

    // Check global
    if (TCJSModule.registeredGlobalModules[jsPath]) {
        return jsPath;
    }

    // Check local
    TCJSModuleLoader moduleLoader = nil;
    NSDictionary<NSString *, TCJSModuleLoader> *loaders = [self registeredModuleLoadersInContext:context];
    NSArray<NSString *> *pathExtensions = [@[@""] arrayByAddingObjectsFromArray:loaders.allKeys];
    for (NSString *basePath in parentModule.paths) {
        for (NSString *pathExtension in pathExtensions) {
            NSString *fullJSPath = [basePath stringByAppendingPathComponent:jsPath].stringByStandardizingPath;
            if (pathExtension.length) {
                fullJSPath = [fullJSPath stringByAppendingPathExtension:pathExtension];
            }

            if ([[NSFileManager defaultManager] fileExistsAtPath:fullJSPath] &&
                [fullJSPath isSubpathOfPath:basePath] &&
                (moduleLoader = loaders[fullJSPath.pathExtension])) {
                if (outLoader) {
                    *outLoader = moduleLoader;
                }
                return fullJSPath;
            }
        }
    }

    return nil;
}

+ (TCJSModule *)loadModuleByPath:(NSString *)jsPath
                    parentModule:(TCJSModule *)parentModule
                         context:(JSContext *)context {
    parentModule = parentModule ?: [TCJSModule mainModuleOfContext:context];

    TCJSModuleLoader moduleLoader = nil;
    NSString *fullJSPath = [self resolve:jsPath parentModule:parentModule loader:&moduleLoader context:context];
    if (!fullJSPath) {
        return nil;
    }

    TCJSModule *module = [self loadedModulesInContext:context][fullJSPath];
    if (!module) {
        if (moduleLoader) {
            module = [[TCJSModule alloc] initWithContext:context];
            if (!(module.loaded = moduleLoader(module, fullJSPath, context) && context.exception == nil)) {
                module.filename = fullJSPath;
                module = nil;
            }
        } else {
            // No module loader ... is global module
            module = TCJSModule.registeredGlobalModules[fullJSPath](context);
        }
    }
    if (module) {
        [self setModule:module asLoadedForPath:fullJSPath context:context];
    }
    return module;
}

+ (JSValue *)globalRequireFunctionInContext:(JSContext *)context {
    JSValue *require = context[@"require"];
    if (!require || require.isUndefined) {
        require = context[@"require"] = [self createNewRequireFunctionForModule:[TCJSModule mainModuleOfContext:context]
                                                                        context:context];
        [self registerDefaultModuleLoaderForContext:context];
    }
    return require;
}

+ (void)registerDefaultModuleLoaderForContext:(JSContext *)context {
    [self registerModuleLoader:^BOOL(TCJSModule *module, NSString *filepath, JSContext *context) {
        NSError *error;
        NSString *script = [[NSString alloc] initWithContentsOfFile:filepath
                                                           encoding:NSUTF8StringEncoding
                                                              error:&error];
        if (script) {
            @autoreleasepool {
                NSURL *sourceURL = [NSURL fileURLWithPath:filepath];
                NSString *paddedScript = [NSString stringWithFormat:
                                          @"(function() {\n"
                                          @"    return (function(exports, module, require, __filename, __dirname) {\n"
                                          @"        /* --- Start of Script Body --- */\n"
                                          @"%@\n"
                                          @"        /* --- End of Script Body --- */\n"
                                          @"    }).apply(arguments[0], arguments);\n"
                                          @"});\n", script];
                JSValue *scriptLoader = (sourceURL ?
                                         [context evaluateScript:paddedScript withSourceURL:sourceURL] :
                                         [context evaluateScript:paddedScript]);
                return [scriptLoader callWithArguments:@[
                    module.exports,
                    module,
                    [self createNewRequireFunctionForModule:module context:context],
                    sourceURL.path,
                    sourceURL.path.stringByDeletingLastPathComponent
                ]];
            }
            return context.exception == nil;
        } else {
            context.exception = [JSValue valueWithNewErrorFromMessage:error.localizedDescription inContext:context];
            return NO;
        }
    } forExtension:@"js" context:context];

    [self registerModuleLoader:^BOOL(TCJSModule *module, NSString *filepath, JSContext *context) {
        NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath:filepath];
        [inputStream open];
        @onExit {
            [inputStream close];
        };

        NSString *errorMessage = nil;
        id result = nil;
        @try {
            NSError *error;
            result = [NSJSONSerialization JSONObjectWithStream:inputStream
                                                       options:NSJSONReadingAllowFragments
                                                         error:&error];
            if (!result && error) {
                errorMessage = error.localizedDescription;
            }
        }
        @catch (NSException *exception) {
            errorMessage = exception.reason;
        }
        @finally {
            module.exports = (result ?
                              [JSValue valueWithObject:result inContext:context] :
                              [JSValue valueWithUndefinedInContext:context]);
            if (errorMessage) {
                context.exception = [JSValue valueWithNewErrorFromMessage:errorMessage inContext:context];
            }
            return result != nil && errorMessage == nil;
        }
    } forExtension:@"json" context:context];
}

+ (JSValue *)createNewRequireFunctionForModule:(TCJSModule *)module context:(JSContext *)context {
    BOOL globalModule = [[TCJSModule mainModuleOfContext:context] isEqual:module];

    JSValue *require = [JSValue valueWithObject:^(NSString *jsPath){
        return [TCJSRequire loadModuleByPath:jsPath parentModule:module context:[JSContext currentContext]].exports;
    } inContext:context];
    require[@"resolve"] = ^(NSString *jsPath) {
        JSContext *context = [JSContext currentContext];
        NSString *fullJSPath = [TCJSRequire resolve:jsPath parentModule:module loader:NULL context:context];
        if (!fullJSPath) {
            NSString *message = BFFormatString(@"Cannot find module '%@'", jsPath);
            context.exception = [JSValue valueWithNewErrorFromMessage:message inContext:context];
        }
        return fullJSPath;
    };

    if (globalModule) {
        require[TCJSRequireExtensionsKey] = [JSValue valueWithNewObjectInContext:context];
        require[TCJSRequireCacheKey] = [JSValue valueWithNewObjectInContext:context];
    } else {
        [TCJSUtil defineProperty:TCJSRequireExtensionsKey
                      enumerable:YES
                    configurable:NO
                        writable:NO
                           value:nil
                          getter:^id _Nullable{
                              return [JSContext currentContext][@"require"][TCJSRequireExtensionsKey];
                          }
                          setter:nil
                        forValue:require];
        [TCJSUtil defineProperty:TCJSRequireCacheKey
                      enumerable:YES
                    configurable:NO
                        writable:NO
                           value:nil
                          getter:^id _Nullable{
                              return [JSContext currentContext][@"require"][TCJSRequireCacheKey];
                          }
                          setter:nil
                        forValue:require];
    }

    return require;
}

@end

@implementation TCJSModule

+ (void)loadExtensionForJSContext:(JSContext *)context {
    TCJSModule *module = context[@"module"] = [[TCJSModule alloc] initWithContext:context];
    NSString *classBundlePath = [NSBundle bundleForClass:TCJSModule.class].bundlePath;
    [module.paths addObject:classBundlePath];
    NSString *mainBundlePath = [NSBundle mainBundle].bundlePath;
    if (![classBundlePath isEqualToString:mainBundlePath]) {
        [module.paths addObject:mainBundlePath];
    }
}

+ (NSMutableDictionary<NSString *, TCJSModule *(^)(JSContext *)> *)registeredGlobalModules {
    static NSMutableDictionary *registeredGlobalModules;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registeredGlobalModules = [NSMutableDictionary dictionaryWithCapacity:2];
    });
    return registeredGlobalModules;
}

+ (void)registerGlobalModuleNamed:(NSString *)globalModuleName witBlock:(nonnull TCJSModule *(^)(JSContext *))block {
    if (block) {
        self.registeredGlobalModules[globalModuleName] = block;
    } else {
        [self.registeredGlobalModules removeObjectForKey:globalModuleName];
    }
}

+ (instancetype)mainModuleOfContext:(JSContext *)context {
    id module = context[@"module"];
    if ([module isKindOfClass:JSValue.class]) {
        return [module toObjectOfClass:TCJSModule.class];
    } else if ([module isKindOfClass:TCJSModule.class]) {
        return module;
    } else {
        return nil;
    }
}

#pragma mark - Object Lifecycle

- (instancetype)init {
    return self = [self initWithContext:nil];
}

- (instancetype)initWithContext:(nullable JSContext *)context {
    if (self = [super init]) {
        context = context ?: [JSContext currentContext];
        NSAssert(context, @"Can't get a JSContext");

        _loaded = NO;
        _moduleID = [NSString randomStringByLength:32];

        TCJSModule *mainModule = [TCJSModule mainModuleOfContext:context];
        if (mainModule) {
            _paths = [mainModule.paths mutableCopy];
        } else {
            _paths = [[NSMutableArray alloc] init];
        }

        self.exports = [JSValue valueWithNewObjectInContext:context];
    }
    return self;
}

- (instancetype)initWithExports:(id)exports context:(nullable JSContext *)context {
    if (self = [self initWithContext:context]) {
        self.exports = exports;
        _loaded = YES;
    }
    return self;
}

- (instancetype)initWithContentOfFile:(NSString *)filepath context:(JSContext *)context {
    if (self = [self initWithContext:context]) {
        _filename = filepath;

        TCJSModuleLoader moduleLoader = [TCJSRequire registeredModuleLoadersInContext:context][filepath.pathExtension];
        if (!(_loaded = moduleLoader && moduleLoader(self, filepath, context) && context.exception == nil)) {
            return self = nil;
        }
    }
    return self;
}

- (void)dealloc {
    self.exports = nil;
}

#pragma mark - Property

- (JSValue *)exports {
    return self.managedExports.value ?: [JSValue valueWithUndefinedInContext:[JSContext currentContext]];
}

- (void)setExports:(JSValue *)exports {
    @synchronized(self) {
        if (self.managedExports && self.managedExports.value) {
            JSContext *context = self.managedExports.value.context ?: [JSContext currentContext];
            NSAssert(context, @"Can't get a JSContext");
            [context.virtualMachine removeManagedReference:self.managedExports withOwner:self];
            self.managedExports = nil;
        }

        if (exports) {
            JSContext *context = exports.context ?: [JSContext currentContext];
            NSAssert(context, @"Can't get a JSContext");
            self.managedExports = [JSManagedValue managedValueWithValue:exports];
            [context.virtualMachine addManagedReference:self.managedExports withOwner:self];
        }
    }
}

@end
