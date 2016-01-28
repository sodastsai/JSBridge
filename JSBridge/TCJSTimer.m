//
//  TCJSTimer.m
//  JSBridge
//
//  Created by sodas on 1/28/16.
//  Copyright © 2016 JSBridge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TCJSBridge/TCJSJavaScriptContext.h>
#import <BenzeneFoundation/BenzeneFoundation.h>

@protocol TCJSTimer <JSExport>

@end

@interface TCJSTimer : NSObject <TCJSTimer, TCJSJavaScriptContextExtension> {
    BOOL _fired;
}

@property (nonatomic, strong, readonly) JSValue *callback;
@property (nonatomic, strong, readonly) NSArray *arguments;
@property (nonatomic, strong) NSTimer *timer;

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
        _callback = callback;
        _arguments = arguments;
        _timer = [NSTimer timerWithTimeInterval:timeout
                                         target:self
                                       selector:@selector(timerTriggered:)
                                       userInfo:nil
                                        repeats:repeat];
    }
    return self;
}

- (void)timerTriggered:(NSTimer *)timer {
    [self.callback callWithArguments:self.arguments];
}

- (void)start {
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

- (void)stop {
    [self.timer invalidate];
}

@end
