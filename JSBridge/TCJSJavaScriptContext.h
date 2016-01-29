//
//  TCJSJavaScriptContext.h
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

#ifndef TCJS_STATIC_INLINE
#define TCJS_STATIC_INLINE static inline
#endif  // ifndef TCJS_STATIC_INLINE

#ifndef TCJS_EXTERN
#ifdef __cplusplus
#define TCJS_EXTERN extern "C"
#else  // ifdef __cplusplus
#define TCJS_EXTERN extern
#endif  // ifdef __cplusplus
#endif  // ifndef TCJ_STATIC_INLINE

NS_ASSUME_NONNULL_BEGIN

@protocol TCJSJavaScriptContextExtension <NSObject>

+ (void)loadExtensionForJSContext:(JSContext *)context;

@end

TCJS_EXTERN void TCJSJavaScriptContextRegisterExtension(Class extension);

TCJS_EXTERN JSContext *TCJSJavaScriptContextCreateContext();

TCJS_EXTERN void TCJSJavaScriptContextSetMainDispatchQueue(JSContext *context,
                                                           dispatch_queue_t _Nullable dispatchQueue);
TCJS_EXTERN dispatch_queue_t _Nullable TCJSJavaScriptContextGetMainDispatchQueue(JSContext *context);
TCJS_EXTERN void TCJSJavaScriptContextSetBackgroundDispatchQueue(JSContext *context,
                                                                 dispatch_queue_t _Nullable dispatchQueue);
TCJS_EXTERN dispatch_queue_t _Nullable TCJSJavaScriptContextGetBackgroundDispatchQueue(JSContext *context);

NS_ASSUME_NONNULL_END
