//
//  TCJSApplication.h
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

@class TCJSConsole;

@protocol TCJSApplication <JSExport>

@property (nonatomic, readonly) NSString *version;
@property (nonatomic, readonly) NSString *build;
@property (nonatomic, readonly) NSString *identifier;

@property (nonatomic, readonly) NSString *locale;
@property (nonatomic, readonly) NSArray<NSString *> *preferredLanguages;

@property (nonatomic, strong, readonly) TCJSConsole *console;

@end

@interface TCJSApplication : NSObject <TCJSApplication, TCJSJavaScriptContextExtension>

+ (instancetype)currentApplication;

@end

@protocol TCJSSystem <JSExport>

@property (nonatomic, readonly) NSString *version;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *model;

@end

@interface TCJSSystem : NSObject <TCJSSystem, TCJSJavaScriptContextExtension>

+ (instancetype)currentSystem;

@end


NS_ASSUME_NONNULL_END
