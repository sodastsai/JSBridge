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

@end

@implementation TCJSModule

@synthesize exports = _exports;

+ (void)loadExtensionForJSContext:(JSContext *)context {
    TCJSModule *module = [[TCJSModule alloc] initWithScript:nil
                                                   sourceFile:nil
                                                    loadPaths:@[[NSBundle mainBundle].bundlePath]];
    module.filename = @".";
    module.loaded = YES;

    context[@"module"] = module;
    JSValue *require = context[@"require"] = [JSValue valueWithObject:^JSValue *(NSString *path) {
        return [module require:path];
    } inContext:context];
    require[@"main"] = module;
}

+ (NSMutableDictionary<NSString *, TCJSModule *(^)(void)> *)registeredGlobalModules {
    static NSMutableDictionary *registeredGlobalModules;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registeredGlobalModules = [NSMutableDictionary dictionaryWithCapacity:2];
    });
    return registeredGlobalModules;
}

+ (void)registerGlobalModuleNamed:(NSString *)globalModuleName withBlock:(TCJSModule *(^)(void))block {
    self.registeredGlobalModules[globalModuleName] = block;
}

+ (instancetype)mainModule {
    id module = [JSContext currentContext][@"module"];
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
    TCJSJavaScriptContextRegisterExtension(self);

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidReceiveMemoryWarning:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:[UIApplication sharedApplication]];
}

- (instancetype)initWithScriptContentsOfFile:(NSString *)path {
    return self = [self initWithScriptContentsOfFile:path loadPaths:nil];
}

- (instancetype)initWithScriptContentsOfFile:(NSString *)path loadPaths:(nullable NSArray<NSString *> *)loadPaths {
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSString *scriptContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        if (scriptContent) {
            return self = [self initWithScript:scriptContent sourceFile:path loadPaths:loadPaths];
        }
    }
    return self = nil;
}

- (instancetype)init {
    return self = [self initWithScript:nil sourceFile:nil loadPaths:nil];
}

- (instancetype)initWithScript:(NSString *)script
                    sourceFile:(NSString *)path
                     loadPaths:(nullable NSArray<NSString *> *)loadPaths {
    if (self = [super init]) {
        // Set load paths if necessary
        if (!loadPaths) {
            TCJSModule *mainModule = [TCJSModule mainModule];
            if (mainModule) {
                loadPaths = mainModule.paths;
            }
        }
        NSAssert(loadPaths, @"There's no global module ... loadPaths must be set");

        // Initialize
        _paths = [loadPaths mutableCopy];
        _exports = [JSValue valueWithNewObjectInContext:[JSContext currentContext]];
        _loaded = NO;
        _filename = path;
        _moduleID = [NSString randomStringByLength:32];

        // Load script
        if (path) {
            [_paths insertObject:path.stringByDeletingLastPathComponent atIndex:0];
        }
        if (script) {
            @autoreleasepool {
                NSString *paddedScript = [NSString stringWithFormat:
                                          @"(function() {\n"
                                          @"    return function(module, exports, require) {\n"
                                          @"        /* --- Start of Script --- */\n"
                                          @"%@\n"
                                          @"        /* --- End of Script Content --- */\n"
                                          @"    };\n"
                                          @"})();", script];
                JSValue *loaderFunc;
                if (path) {
                    loaderFunc = [[JSContext currentContext] evaluateScript:paddedScript
                                                              withSourceURL:[NSURL fileURLWithPath:path]];
                } else {
                    loaderFunc = [[JSContext currentContext] evaluateScript:paddedScript];
                }
                [loaderFunc callWithArguments:@[
                    self,
                    self.exports,
                    ^JSValue *(NSString *path){ return [self require:path]; },
                ]];
                _loaded = YES;
            }
        }
    }
    return self;
}

- (void)dealloc {
    [self.class.sharedRequireCache removeObjectForKey:self.moduleID];
}

#pragma mark - Notification

+ (void)applicationDidReceiveMemoryWarning:(NSNotification *)notification {
    [self.sharedRequireCache removeAllObjects];
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
        requiredCache = self.class.sharedRequireCache[self.moduleID] = [[NSCache alloc] init];
        requiredCache.countLimit = 10;
    }
    return requiredCache;
}

- (nullable JSValue *)require:(NSString *)jsPath {
    JSContext *currentContext = [JSContext currentContext];
    TCJSModule *module = [self.requireCache objectForKey:jsPath];
    if (!module) {
        if ([jsPath hasSuffix:@".js"]) {
            // Find file
            NSString *fullJSPath = nil;
            for (NSString *path in self.paths) {
                fullJSPath = [path stringByAppendingPathComponent:jsPath].stringByStandardizingPath;
                if ([fullJSPath isSubpathOfPath:path] &&
                    [[NSFileManager defaultManager] fileExistsAtPath:fullJSPath]) {
                    break;
                } else {
                    fullJSPath = nil;
                }
            }
            if (fullJSPath) {
                module = [[TCJSModule alloc] initWithScriptContentsOfFile:fullJSPath loadPaths:self.paths];
            }
        } else {
            TCJSModule *(^globalModuleLoader)(void) = self.class.registeredGlobalModules[jsPath];
            if (globalModuleLoader) {
                @autoreleasepool {
                    module = globalModuleLoader();
                }
            }
        }

        if (module) {
            [self.requireCache setObject:module forKey:jsPath];
        } else {
            NSString *message = [NSString stringWithFormat:@"Can't load module: %@", jsPath];
            currentContext.exception = [JSValue valueWithNewErrorFromMessage:message inContext:currentContext];
        }
    }
    return module.exports ?: [JSValue valueWithUndefinedInContext:currentContext];
}

@end
