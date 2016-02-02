//
//  TCJSTimer.m
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
#import <TCJSBridge/TCJSJavaScriptContext.h>
#import <BenzeneFoundation/BenzeneFoundation.h>

@protocol TCJSTimer <JSExport>

@end

@interface TCJSTimer : NSObject <TCJSJavaScriptContextExtension, TCJSTimer>

@property (nonatomic, strong) JSManagedValue *callbackManagedValue;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) BOOL repeat;

- (instancetype)initWithCallback:(JSValue *)callback
                       arguments:(NSArray *)arguments
                         timeout:(NSTimeInterval)timeout
                          repeat:(BOOL)repeat NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)start;
- (void)stop;

@end

@implementation TCJSTimer

+ (void)load {
    TCJSJavaScriptContextRegisterExtension(self);
}

+ (void)loadExtensionForJSContext:(JSContext *)context {
    JSValue *globalObject = context.globalObject;

    globalObject[@"setTimeout"] = ^TCJSTimer *(JSValue *callback, long timeout) {
        NSArray *arguments = [[JSContext currentArguments] subarrayFromIndex:2];
        TCJSTimer *timer = [[TCJSTimer alloc] initWithCallback:callback
                                                     arguments:arguments
                                                       timeout:timeout/1000.
                                                        repeat:NO];
        [timer start];
        return timer;
    };
    globalObject[@"setInterval"] = ^TCJSTimer *(JSValue *callback, long timeout) {
        NSArray *arguments = [[JSContext currentArguments] subarrayFromIndex:2];
        TCJSTimer *timer = [[TCJSTimer alloc] initWithCallback:callback
                                                     arguments:arguments
                                                       timeout:timeout/1000.
                                                        repeat:YES];
        [timer start];
        return timer;
    };
    globalObject[@"clearInterval"] = globalObject[@"clearTimeout"] = ^(TCJSTimer *timer) {
        [timer stop];
    };
}

- (instancetype)initWithCallback:(JSValue *)callback
                       arguments:(NSArray *)arguments
                         timeout:(NSTimeInterval)timeout
                          repeat:(BOOL)repeat {
    if (self = [super init]) {
        JSContext *context = [JSContext currentContext];
        JSValue *_callback = (arguments.count == 0 ?
                              callback :
                              [[context evaluateScript:
                                @"(function() {\n"
                                @"    return function(callback, args) {\n"
                                @"        return function() {\n"
                                @"            callback.apply(this, args);"
                                @"        };\n"
                                @"    };\n"
                                @"})();"]
                               callWithArguments:@[callback, arguments]]);
        _callbackManagedValue = [JSManagedValue managedValueWithValue:_callback];
        [context.virtualMachine addManagedReference:_callbackManagedValue withOwner:self];

        _timer = [NSTimer timerWithTimeInterval:timeout
                                         target:self
                                       selector:@selector(timerTriggered:)
                                       userInfo:nil
                                        repeats:_repeat = repeat];
    }
    return self;
}

- (void)dealloc {
    [self cleanCallback];
}

- (void)cleanCallback {
    JSContext *context = self.callbackManagedValue.value.context;
    [context.virtualMachine removeManagedReference:self.callbackManagedValue withOwner:self];
    self.callbackManagedValue = nil;
}

- (void)timerTriggered:(NSTimer *)timer {
    [self.callbackManagedValue.value callWithArguments:@[]];
    if (!self.repeat) {
        [self cleanCallback];
    }
}

- (void)start {
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

- (void)stop {
    [self.timer invalidate];
    [self cleanCallback];
}

@end
