//
//  TCJSApplication.m
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

#import "TCJSApplication.h"
#import <UIKit/UIKit.h>
#import <BenzeneFoundation/BenzeneUIKit.h>
#import "TCJSConsole.h"
#import "TCJSModule.h"
#import "TCJSUtils.h"

@protocol TCJSApplication <JSExport>

@property (nonatomic, readonly) NSString *version;
@property (nonatomic, readonly) NSString *build;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *name;

@property (nonatomic, readonly) NSString *locale;
@property (nonatomic, readonly) NSArray<NSString *> *preferredLanguages;

@property (nonatomic, strong, readonly) TCJSConsole *console;

@end

@interface TCJSApplication () <TCJSApplication>

@property (nonatomic, strong, readonly) NSMutableSet<JSContext *> *contextPool;

@end

NSString *const TCJSApplicationBecomeActiveJSEventName = @"becomeActive";
NSString *const TCJSApplicationResignActiveJSEventName = @"resignActive";

@implementation TCJSApplication

@synthesize console = _console;

+ (void)load {
    TCJSJavaScriptContextRegisterExtension(self);
}

+ (void)loadExtensionForJSContext:(JSContext *)context {
    TCJSModule *module = [[TCJSModule alloc] initWithContext:context];

    TCJSModule *eventsModule = [TCJSRequire loadModuleByPath:@"events" parentModule:module context:context];
    JSValue *EventEmitter = eventsModule.exports[@"EventEmitter"];
    JSValue *application = [EventEmitter constructWithArguments:@[]];

    [TCJSUtil defineReadonlyProperty:@"_nativeObject"
                          forJSValue:application
                           withValue:[TCJSApplication currentApplication]];

    BFObjectInspectionEnumeratePropertyOfProtocol(@protocol(TCJSApplication), ^(objc_property_t  _Nonnull property,
                                                                                const char * _Nonnull propertyName,
                                                                                ext_propertyAttributes * _Nonnull attr,
                                                                                Protocol * _Nonnull ProtocolOfProperty,
                                                                                BOOL * _Nonnull stop) {
        [TCJSUtil defineProperty:@(propertyName)
                        forValue:application
           withNativeObjectNamed:@"_nativeObject"
                         keyPath:@(propertyName)
                        readonly:YES];
    });
    [TCJSUtil defineReadonlyProperty:TCJSApplicationBecomeActiveJSEventName
                          forJSValue:application
                           withValue:TCJSApplicationBecomeActiveJSEventName];
    [TCJSUtil defineReadonlyProperty:TCJSApplicationResignActiveJSEventName
                          forJSValue:application
                           withValue:TCJSApplicationResignActiveJSEventName];

    context[@"application"] = module.exports = application;
    [[TCJSApplication currentApplication].contextPool addObject:context];
}

+ (void)deactivateExtensionForJSContext:(JSContext *)context {
    [[TCJSApplication currentApplication].contextPool removeObject:context];
}

+ (instancetype)currentApplication {
    static TCJSApplication *application;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        application = [[TCJSApplication alloc] init];
    });
    return application;
}

- (instancetype)init {
    if (self = [super init]) {
        _console = [[TCJSConsole alloc] init];
        _contextPool = [NSMutableSet setWithCapacity:1];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:[UIApplication sharedApplication]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillResignActive:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:[UIApplication sharedApplication]];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notifications

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    for (JSContext *context in self.contextPool) {
        [context[@"application"] invokeMethod:@"emit" withArguments:@[TCJSApplicationBecomeActiveJSEventName]];
    }
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    for (JSContext *context in self.contextPool) {
        [context[@"application"] invokeMethod:@"emit" withArguments:@[TCJSApplicationResignActiveJSEventName]];
    }
}

#pragma mark - Properties

- (NSString *)version {
    return [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
}

- (NSString *)name {
    NSDictionary *bundleInfo = [NSBundle mainBundle].infoDictionary;
    return bundleInfo[@"CFBundleDisplayName"] ?: bundleInfo[@"CFBundleName"];
}

- (NSString *)build {
    return [NSBundle mainBundle].infoDictionary[(__bridge NSString *)kCFBundleVersionKey];
}

- (NSString *)identifier {
    return [NSBundle mainBundle].bundleIdentifier;
}

- (NSString *)locale {
    return [NSLocale currentLocale].localeIdentifier;
}

- (NSArray<NSString *> *)preferredLanguages {
    return [NSLocale preferredLanguages];
}

@end

@protocol TCJSSystem <JSExport>

@property (nonatomic, readonly) NSString *version;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *model;
@property (nonatomic, readonly) NSString *bridgeVersion;

#if DEBUG
- (void)_garbageCollect;
#endif

@end

@interface TCJSSystem () <TCJSSystem>

@end

@implementation TCJSSystem

+ (void)load {
    TCJSJavaScriptContextRegisterExtension(self);
}

+ (void)loadExtensionForJSContext:(JSContext *)context {
    context[@"system"] = [TCJSSystem currentSystem];
}

+ (instancetype)currentSystem {
    static TCJSSystem *system;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        system = [[TCJSSystem alloc] init];
    });
    return system;
}

- (NSString *)version {
    return [UIDevice currentDevice].systemVersion;
}

- (NSString *)name {
    return [UIDevice currentDevice].systemName;
}

- (NSString *)model {
    return [UIDevice currentDevice].modelIdentifier;
}

- (void)_garbageCollect {
    JSGarbageCollect([JSContext currentContext].JSGlobalContextRef);
}

- (NSString *)bridgeVersion {
    return @"0.0.1";  // TODO: Integrate with build tool
}

@end
