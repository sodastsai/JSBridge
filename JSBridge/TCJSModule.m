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
#import <BenzeneFoundation/BenzeneFoundation.h>

@interface TCJSModule ()

@property (nonatomic, strong) NSString *moduleID;
@property (nonatomic, strong, readwrite) NSString *filename;
@property (nonatomic, assign, readwrite, getter=isLoaded) BOOL loaded;
@property (nonatomic, strong, readwrite) NSMutableArray<NSString *> *paths;

@property (nonatomic, strong) JSManagedValue *managedExports;
@property (nonatomic, strong) JSManagedValue *managedPool;

@end

TCJS_STATIC_INLINE JSValue *TCJSModuleCannotFindModule(JSContext *context, NSString *modulePath) {
    NSString *message = BFFormatString(@"Cannot find module '%@'", modulePath);
    return [JSValue valueWithNewErrorFromMessage:message inContext:context];
}

@implementation TCJSModule

+ (NSMutableDictionary<NSString *, TCJSModule *(^)(JSContext *)> *)registeredGlobalModules {
    static NSMutableDictionary *registeredGlobalModules;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registeredGlobalModules = [NSMutableDictionary dictionaryWithCapacity:2];
    });
    return registeredGlobalModules;
}

+ (void)registerGlobalModuleNamed:(NSString *)globalModuleName withBlock:(TCJSModule *(^)(JSContext *))block {
    self.registeredGlobalModules[globalModuleName] = block;
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

+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidReceiveMemoryWarning:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:[UIApplication sharedApplication]];
}

+ (instancetype)moduleWithExports:(JSValue *)exports {
    TCJSModule *module = [[TCJSModule alloc] init];
    module.exports = exports;
    return module;
}

- (instancetype)initWithScriptContentsOfFile:(NSString *)path context:(nullable JSContext *)context {
    return self = [self initWithScriptContentsOfFile:path loadPaths:nil context:context];
}

- (instancetype)initWithScriptContentsOfFile:(NSString *)path
                                   loadPaths:(nullable NSArray<NSString *> *)loadPaths
                                     context:(nullable JSContext *)context{
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSString *scriptContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        if (scriptContent) {
            return self = [self initWithScript:scriptContent
                                    sourceFile:path
                                     loadPaths:loadPaths
                                       context:context
                                          pool:nil];
        }
    }
    return self = nil;
}

- (instancetype)init {
    return self = [self initWithScript:nil sourceFile:nil loadPaths:nil context:nil pool:nil];
}

- (nullable instancetype)initWithContext:(JSContext *)context {
    return self = [self initWithScript:nil sourceFile:nil loadPaths:nil context:context pool:nil];
}

- (instancetype)initWithScript:(NSString *)script
                    sourceFile:(NSString *)path
                     loadPaths:(nullable NSArray<NSString *> *)loadPaths
                       context:(nullable JSContext *)context
                          pool:(nullable NSMutableDictionary *)pool {
    if (self = [super init]) {
        // Set load paths if necessary
        context = context ?: [JSContext currentContext];
        if (!loadPaths) {
            TCJSModule *mainModule = [TCJSModule mainModuleOfContext:context];
            if (mainModule) {
                loadPaths = mainModule.paths;
            } else {
                loadPaths = @[];
            }
        }
        NSAssert(context, @"Cann't find a JSContext");

        // Initialize
        _paths = [loadPaths mutableCopy];
        _loaded = NO;
        _filename = path;
        _moduleID = [NSString randomStringByLength:32];

        self.exports = [JSValue valueWithNewObjectInContext:context];
        self.pool = [JSValue valueWithNewObjectInContext:context];

        // Load script
        if (path) {
            [_paths insertObject:path.stringByDeletingLastPathComponent atIndex:0];
        }
        if (script) {
            [self evaluateScript:script sourceURL:path?[NSURL fileURLWithPath:path]:nil context:context];
            if (!(_loaded = context.exception == nil)) {
                return self = nil;
            }
        } else {
            _loaded = YES;
        }
    }
    return self;
}

- (void)dealloc {
    self.exports = nil;
    [self.class.sharedRequireCache removeObjectForKey:self.moduleID];
}

#pragma mark - Notification

+ (void)applicationDidReceiveMemoryWarning:(NSNotification *)notification {
    [self.sharedRequireCache removeAllObjects];
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

- (JSValue *)pool {
    return self.managedPool.value ?: [JSValue valueWithUndefinedInContext:[JSContext currentContext]];
}

- (void)setPool:(JSValue *)pool {
    @synchronized(self) {
        if (self.managedPool && self.managedPool.value) {
            JSContext *context = self.managedPool.value.context ?: [JSContext currentContext];
            NSAssert(context, @"Can't get a JSContext");
            [context.virtualMachine removeManagedReference:self.managedPool withOwner:self];
            self.managedPool = nil;
        }

        if (pool) {
            JSContext *context = pool.context ?: [JSContext currentContext];
            NSAssert(context, @"Can't get a JSContext");
            self.managedPool = [JSManagedValue managedValueWithValue:pool];
            [context.virtualMachine addManagedReference:self.managedPool withOwner:self];
        }
    }
}

#pragma mark - Require Method

+ (NSMutableDictionary<NSString *, NSCache<NSString *, TCJSModule *> *> *)sharedRequireCache {
    static NSMutableDictionary *dictionary;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dictionary = [NSMutableDictionary dictionary];
    });
    return dictionary;
}

- (NSCache<NSString *, TCJSModule *> *)requireCache {
    NSCache<NSString *, TCJSModule *> *requiredCache = self.class.sharedRequireCache[self.moduleID];
    if (!requiredCache) {
        @synchronized(self) {
            if (!requiredCache) {
                requiredCache = self.class.sharedRequireCache[self.moduleID] = [[NSCache alloc] init];
                requiredCache.countLimit = 10;
            }
        }
    }
    return requiredCache;
}

- (void)clearRequireCache {
    [self.requireCache removeAllObjects];
}

- (nullable NSString *)resolve:(NSString *)jsPath {
    NSString *fullJSPath = nil;
    for (NSString *path in self.paths) {
        fullJSPath = [path stringByAppendingPathComponent:jsPath].stringByStandardizingPath;
        if ([fullJSPath isSubpathOfPath:path] &&
            [[NSFileManager defaultManager] fileExistsAtPath:fullJSPath]) {
            return fullJSPath;
        } else {
            fullJSPath = nil;
        }
    }

    JSContext *context = [JSContext currentContext];
    if (!fullJSPath && context) {
        context.exception = TCJSModuleCannotFindModule(context, jsPath);
    }

    return nil;
}

- (nullable JSValue *)require:(NSString *)jsPath {
    JSContext *context = [JSContext currentContext];
    return [self moduleByRequiringPath:jsPath context:context].exports ?: [JSValue valueWithUndefinedInContext:context];
}

- (nullable TCJSModule *)moduleByRequiringPath:(NSString *)jsPath context:(JSContext *)context {
    TCJSModule *module = [self.requireCache objectForKey:jsPath];
    if (!module) {
        TCJSModule *(^globalModuleLoader)(JSContext *) = self.class.registeredGlobalModules[jsPath];
        if (globalModuleLoader) {
            module = globalModuleLoader(context);
            module.loaded = YES;
        } else {
            NSString *fullJSPath = [self resolve:jsPath];
            if (fullJSPath) {
                module = [[TCJSModule alloc] initWithScriptContentsOfFile:fullJSPath
                                                                loadPaths:self.paths
                                                                  context:context];
            }
        }

        if (module) {
            [self.requireCache setObject:module forKey:jsPath];
        } else {
            context.exception = TCJSModuleCannotFindModule(context, jsPath);
        }
    }

    return module;
}

- (JSValue *)evaluateScript:(NSString *)script sourceURL:(nullable NSURL *)sourceURL context:(JSContext *)context {
    @autoreleasepool {
        NSString *paddedScript = [NSString stringWithFormat:
                                  @"(function() {\n"
                                  @"    return function(module) {\n"
                                  @"        return (function _moduleContext() {  // `this` is `module`\n"
                                  @"            function _require(path) {\n"
                                  @"                return module.require(path);\n"
                                  @"            }\n"
                                  @"            return (function _body(module, exports, require) {\n"
                                  @"                /* --- Start of Script Body --- */\n"
                                  @"%@\n"
                                  @"                /* --- End of Script Body --- */\n"
                                  @"            }).call(this.exports, this, this.exports, _require);\n"
                                  @"        }).call(module);\n"
                                  @"    }\n"
                                  @"})();\n", script];
        JSValue *scriptLoader = (sourceURL ?
                                 [context evaluateScript:paddedScript withSourceURL:sourceURL] :
                                 [context evaluateScript:paddedScript]);
        return [scriptLoader callWithArguments:@[self]];
    }
}

@end
