//
//  TCJSEvents.m
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
#import "TCJSModule.h"
#import "TCJSUtils.h"
#import <objc/runtime.h>

@interface TCJSEvents : NSObject

@end

@protocol TCJSNotificationHandler <JSExport>

+ (id)on;
+ (void)off:(id)observer;

@end

static char TCJSNotificationHandlerObserverHandlerAssociationKey;

@interface TCJSNotificationHandler : NSObject <TCJSNotificationHandler>

+ (id)on:(NSString *)notificationName object:(nullable id)notificationObject handler:(JSValue *)handler;

@end

@implementation TCJSEvents

+ (void)load {
    [TCJSModule registerGlobalModuleNamed:@"events" withBlock:^TCJSModule *(JSContext *context) {
        NSString *jsPath = [[NSBundle bundleForClass:TCJSEvents.class] pathForResource:@"TCJSEvents" ofType:@"js"];
        TCJSModule *module = [[TCJSModule alloc] initWithScriptContentsOfFile:jsPath context:context];
        module.exports[@"EventCenter"] = [TCJSNotificationHandler class];
        return module;
    }];
}

@end

@implementation TCJSNotificationHandler

+ (id)on {
    JSContext *context = [JSContext currentContext];
    NSArray<JSValue *> *arguments = [JSContext currentArguments];

    JSValue *nameValue;
    JSValue *objectValue;
    JSValue *handler;
    if (arguments.count == 2) {
        nameValue = arguments[0];
        handler = arguments[1];
    } else if (arguments.count >= 3) {
        nameValue = arguments[0];
        objectValue = arguments[1];
        handler = arguments[2];
    }

    if (!nameValue.isString) {
        context.exception = [JSValue valueWithNewErrorFromMessage:@"name should be a string" inContext:context];
        return nil;
    }
    if (!handler) {
        context.exception = [JSValue valueWithNewErrorFromMessage:@"handler should be a function" inContext:context];
        return nil;
    }

    return [self on:nameValue.toString object:objectValue.toObject handler:handler];
}

+ (id)on:(NSString *)notificationName object:(id)notificationObject handler:(JSValue *)handler {
    JSManagedValue *handlerManagedValue = [JSManagedValue managedValueWithValue:handler];
    id<NSObject> observer = [[NSNotificationCenter defaultCenter]
                             addObserverForName:notificationName
                             object:notificationObject
                             queue:nil
                             usingBlock:^(NSNotification * _Nonnull notification) {
                                 JSValue *handler = handlerManagedValue.value;
                                 [handler callWithArguments:@[
                                     notification.name,
                                     notification.object ?: [NSNull null],
                                     notification.userInfo ?: @{},
                                 ]];
                             }];
    objc_setAssociatedObject(observer,
                             &TCJSNotificationHandlerObserverHandlerAssociationKey,
                             handlerManagedValue,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [handler.context.virtualMachine addManagedReference:handlerManagedValue withOwner:observer];
    return observer;
}

+ (void)off:(id)observer {
    JSManagedValue *handlerManagedValue =
        objc_getAssociatedObject(observer, &TCJSNotificationHandlerObserverHandlerAssociationKey);
    [handlerManagedValue.value.context.virtualMachine removeManagedReference:handlerManagedValue withOwner:observer];
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
}

@end
