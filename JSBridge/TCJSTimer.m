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

@interface TCJSTimer : NSObject <TCJSJavaScriptContextExtension>

@property (nonatomic, strong, readonly) NSString *timerId;

@property (nonatomic, strong, readonly) JSValue *callback;
@property (nonatomic, strong, readonly) NSArray *arguments;
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

    globalObject[@"setTimeout"] = ^NSString *(JSValue *callback, long timeout) {
        NSArray *arguments = [[JSContext currentArguments] subarrayFromIndex:2];
        TCJSTimer *timer = [[TCJSTimer alloc] initWithCallback:callback
                                                     arguments:arguments
                                                       timeout:timeout/1000.
                                                        repeat:NO];
        [timer start];
        return timer.timerId;
    };
    globalObject[@"setInterval"] = ^NSString *(JSValue *callback, long timeout) {
        NSArray *arguments = [[JSContext currentArguments] subarrayFromIndex:2];
        TCJSTimer *timer = [[TCJSTimer alloc] initWithCallback:callback
                                                     arguments:arguments
                                                       timeout:timeout/1000.
                                                        repeat:YES];
        [timer start];
        return timer.timerId;
    };
    globalObject[@"clearInterval"] = globalObject[@"clearTimeout"] = ^(NSString *timerId) {
        [[TCJSTimer timersPool][timerId] stop];
    };
}

+ (NSMutableDictionary<NSString *, TCJSTimer *> *)timersPool {
    static NSMutableDictionary *dict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dict = [NSMutableDictionary dictionary];
    });
    return dict;
}

- (instancetype)initWithCallback:(JSValue *)callback
                       arguments:(NSArray *)arguments
                         timeout:(NSTimeInterval)timeout
                          repeat:(BOOL)repeat {
    if (self = [super init]) {
        _callback = callback;
        _arguments = arguments;
        _timer = [NSTimer timerWithTimeInterval:timeout
                                         target:self
                                       selector:@selector(timerTriggered:)
                                       userInfo:nil
                                        repeats:repeat];
        _repeat = repeat;
        _timerId = [NSString randomStringByLength:32];
        [TCJSTimer timersPool][_timerId] = self;
    }
    return self;
}

- (void)timerTriggered:(NSTimer *)timer {
    [self.callback callWithArguments:self.arguments];
    if (!self.repeat) {
        [[TCJSTimer timersPool] removeObjectForKey:self.timerId];
    }
}

- (void)start {
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

- (void)stop {
    [self.timer invalidate];
    [[TCJSTimer timersPool] removeObjectForKey:self.timerId];
}

@end
