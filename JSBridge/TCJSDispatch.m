//
//  TCJSDispatch.m
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
#import "TCJSDispatch.h"
#import "TCJSModule.h"
#import "TCJSUtils.h"
#import <BenzeneFoundation/BenzeneFoundation.h>

NSString *const TCJSDispatchManagerUIQueueName = @"TCJSDispatchManagerUIQueue";
NSString *const TCJSDispatchManagerIOQueueName = @"TCJSDispatchManagerIOQueue";
NSString *const TCJSDispatchManagerMainQueueName = @"TCJSDispatchManagerMainQueue";
NSString *const TCJSDispatchManagerBackgroundQueueName = @"TCJSDispatchManagerBackgroundQueue";

@protocol TCJSDispatchManager <JSExport>

@property (nonatomic, strong, readonly, nullable) NSString *uiQueue;
@property (nonatomic, strong, readonly) NSString *ioQueue;
@property (nonatomic, strong, readonly) NSString *mainQueue;
@property (nonatomic, strong, readonly) NSString *backgroundQueue;

- (void)async;

@end

@interface TCJSDispatchManager () <TCJSDispatchManager>

@end

@implementation TCJSDispatchManager

+ (void)load {
    [TCJSModule registerGlobalModuleNamed:@"dispatch" witBlock:^TCJSModule * _Nonnull(JSContext * _Nonnull context) {
        return [[TCJSModule alloc] initWithExports:[JSValue valueWithObject:[TCJSDispatchManager sharedManager]
                                                                  inContext:context]
                                           context:context];
    }];
}

+ (instancetype)sharedManager {
    static TCJSDispatchManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[TCJSDispatchManager alloc] init];
    });
    return sharedManager;
}

+ (void)asyncExecute:(NSArray *(^)(JSContext *))block callback:(JSValue *)callback {
    JSContext *context = [JSContext currentContext];
    dispatch_async(TCJSJavaScriptContextGetBackgroundDispatchQueue(context), ^{
        NSArray *arguments = block(context);
        dispatch_async(TCJSJavaScriptContextGetMainDispatchQueue(context), ^{
            if (callback && [TCJSUtil isFunction:callback context:context]) {
                [callback callWithArguments:arguments?:@[]];
            }
        });
    });
}

#pragma mark - Properties

- (nullable NSString *)uiQueue {
    return self.shouldExposeUIQueue ? TCJSDispatchManagerUIQueueName : nil;
}

- (NSString *)ioQueue {
    return TCJSDispatchManagerIOQueueName;
}

- (NSString *)mainQueue {
    return TCJSDispatchManagerMainQueueName;
}

- (NSString *)backgroundQueue {
    return TCJSDispatchManagerBackgroundQueueName;
}

#pragma mark - Methods

typedef BFPair<dispatch_queue_t, dispatch_block_t> TCJSDispatchPair;

- (nullable dispatch_queue_t)dispatchQueueFromQueueName:(NSString *)queueName {
    JSContext *context = [JSContext currentContext];
    if ([queueName isEqualToString:self.mainQueue]) {
        return TCJSJavaScriptContextGetMainDispatchQueue(context);
    } else if ([queueName isEqualToString:self.backgroundQueue]) {
        return TCJSJavaScriptContextGetBackgroundDispatchQueue(context);
    } else if ([queueName isEqualToString:self.ioQueue]) {
        return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    } else if ([queueName isEqualToString:self.uiQueue]) {
        return dispatch_get_main_queue();
    } else {
        return nil;
    }
}

- (nullable TCJSDispatchPair *)dispatchBlockFromJSArguments {
    NSString *const _noFunctionErrorMessage = @"Can't get function to call";
    JSContext *context = [JSContext currentContext];
    dispatch_queue_t const _defaultQueue = TCJSJavaScriptContextGetBackgroundDispatchQueue(context);

    NSArray<JSValue *> *arguments = [JSContext currentArguments];
    if (arguments.count == 0) {
        // ..........
        context.exception = [JSValue valueWithNewErrorFromMessage:_noFunctionErrorMessage inContext:context];
        return nil;
    } else if (arguments.count == 1) {
        // Expect Arguments: [func]
        JSValue *function = arguments[0];
        if ([TCJSUtil isFunction:function context:context]) {
            return [TCJSDispatchPair pairWithObject:_defaultQueue andObject:^{
                [function callWithArguments:@[]];
            }];
        } else {
            context.exception = [JSValue valueWithNewErrorFromMessage:_noFunctionErrorMessage inContext:context];
            return nil;
        }
    } else {
        dispatch_queue_t queue;
        dispatch_block_t block;
        if (arguments[0].isString && [TCJSUtil isFunction:arguments[1] context:context]) {
            // Expect Arguments: [str, func, ....]
            queue = [self dispatchQueueFromQueueName:arguments[0].toString];
            if (!queue) {
                context.exception = [JSValue valueWithNewErrorFromMessage:@"Can't get a queue for dispatching function"
                                                                inContext:context];
                return nil;
            }
            block = ^{
                [arguments[1] callWithArguments:[arguments subarrayFromIndex:2]];
            };
        } else if ([TCJSUtil isFunction:arguments[0] context:context]) {
            // Expect Arguments: [func, ....]
            queue = _defaultQueue;
            block = ^{
                [arguments[0] callWithArguments:[arguments subarrayFromIndex:1]];
            };
        } else {
            NSString *message = BFFormatString(@"Unexcepted argument type %@ at 0",
                                               [TCJSUtil toString:arguments[0] context:context]);
            context.exception = [JSValue valueWithNewErrorFromMessage:message inContext:context];
            return nil;
        }
        return [TCJSDispatchPair pairWithObject:queue andObject:block];
    }
}

- (void)async {
    TCJSDispatchPair *dispatch = [self dispatchBlockFromJSArguments];
    if (dispatch) {
        dispatch_async(dispatch.firstObject, dispatch.secondObject);
    }
}

@end
