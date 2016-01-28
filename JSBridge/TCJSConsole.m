//
//  TCJSConsole.m
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

#import "TCJSConsole.h"
#import "TCJSUtils.h"

@implementation TCJSConsole

- (void)printMessageForJSSelector:(SEL)selector {
    NSString *message = [TCJSUtil format];
    if (self.outputConsole) {
        [self.outputConsole writeConsoleMessage:message
                                          level:NSStringFromSelector(selector)
                           forJavaScriptContext:[JSContext currentContext]];
    } else {
        message = [NSString stringWithFormat:@"[%@|console.%@] %@",
                   [JSContext currentContext].name ?: @"JSCore",
                   NSStringFromSelector(selector), message];
        NSLog(@"%@", message);
    }
}

- (void)debug {
    [self printMessageForJSSelector:_cmd];
}

- (void)log {
    [self printMessageForJSSelector:_cmd];
}

- (void)info {
    [self printMessageForJSSelector:_cmd];
}

- (void)error {
    [self printMessageForJSSelector:_cmd];
}

- (void)warn {
    [self printMessageForJSSelector:_cmd];
}

@end
