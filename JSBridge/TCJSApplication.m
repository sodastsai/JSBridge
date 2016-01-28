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

@implementation TCJSApplication

@synthesize console = _console;

+ (void)load {
    TCJSJavaScriptContextRegisterExtension(self);
}

+ (void)loadExtensionForJSContext:(JSContext *)context {
    context[@"application"] = [TCJSApplication currentApplication];
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
    }
    return self;
}

- (NSString *)version {
    return [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
}

- (NSString *)build {
    return [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey];
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

@end
