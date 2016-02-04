//
//  TCJSJavaScriptContext.m
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

#import "TCJSJavaScriptContext.h"
#import "TCJSModule.h"
#import "TCJSUtils.h"
#import <objc/runtime.h>

TCJS_EXTERN NSMutableSet<Class> *TCJSJavaScriptContextRegisteredExtensions();

#pragma mark - Main

TCJS_EXTERN void TCJSJavaScriptContextSetupContext(JSContext *context) {
    // shortcut of globals
    [TCJSUtil defineProperty:@"global"
                  enumerable:YES
                configurable:NO
                    writable:NO
                       value:nil
                      getter:^id _Nullable{ return [JSContext currentContext].globalObject; }
                      setter:nil
                    forValue:context.globalObject];
    [TCJSUtil defineProperty:@"root"
                  enumerable:YES
                configurable:NO
                    writable:NO
                       value:nil
                      getter:^id _Nullable{ return [JSContext currentContext].globalObject; }
                      setter:nil
                    forValue:context.globalObject];

    // Load extensions
    [TCJSModule loadExtensionForJSContext:context];
    for (Class ExtClass in TCJSJavaScriptContextRegisteredExtensions()) {
        [ExtClass loadExtensionForJSContext:context];
    }
}

TCJS_EXTERN void TCJSJavaScriptContextDeactivateContext(JSContext *context) {
    for (Class ExtClass in TCJSJavaScriptContextRegisteredExtensions()) {
        if ([ExtClass respondsToSelector:@selector(deactivateExtensionForJSContext:)]) {
            [ExtClass deactivateExtensionForJSContext:context];
        }
    }
    context.exception = nil;
}

#pragma mark - Extension

TCJS_EXTERN NSMutableSet<Class> *TCJSJavaScriptContextRegisteredExtensions() {
    static NSMutableSet *extensions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        extensions = [NSMutableSet setWithCapacity:10];
    });
    return extensions;
}

TCJS_EXTERN void TCJSJavaScriptContextRegisterExtension(Class extension) {
    if (![extension conformsToProtocol:@protocol(TCJSJavaScriptContextExtension)]) {
        [NSException
         raise:NSInternalInconsistencyException
         format:@"Class \"%@\" doesn't conform to protocol \"%@\"",
         extension, NSStringFromProtocol(@protocol(TCJSJavaScriptContextExtension))];
    }
    [TCJSJavaScriptContextRegisteredExtensions() addObject:extension];
}

#pragma mark - Dispatch Queue

static char TCJSJavaScriptContextMainDispatchQueueAssociationKey;
static char TCJSJavaScriptContextBackgroundDispatchQueueAssociationKey;

TCJS_EXTERN void TCJSJavaScriptContextSetMainDispatchQueue(JSContext *context,
                                                           dispatch_queue_t _Nullable dispatchQueue) {
    objc_setAssociatedObject(context,
                             &TCJSJavaScriptContextMainDispatchQueueAssociationKey,
                             dispatchQueue,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

TCJS_EXTERN dispatch_queue_t _Nullable TCJSJavaScriptContextGetMainDispatchQueue(JSContext *context) {
    return (objc_getAssociatedObject(context, &TCJSJavaScriptContextMainDispatchQueueAssociationKey) ?:
            dispatch_get_main_queue());
}

TCJS_EXTERN void TCJSJavaScriptContextSetBackgroundDispatchQueue(JSContext *context,
                                                                 dispatch_queue_t _Nullable dispatchQueue) {
    objc_setAssociatedObject(context,
                             &TCJSJavaScriptContextBackgroundDispatchQueueAssociationKey,
                             dispatchQueue,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

TCJS_EXTERN dispatch_queue_t _Nullable TCJSJavaScriptContextGetBackgroundDispatchQueue(JSContext *context) {
    return (objc_getAssociatedObject(context, &TCJSJavaScriptContextBackgroundDispatchQueueAssociationKey) ?:
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
}
