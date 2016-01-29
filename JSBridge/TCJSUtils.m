//
//  TCJSUtils.m
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

#import "TCJSUtils.h"
#import "TCJSModule.h"
#import <BenzeneFoundation/BenzeneFoundation.h>

@implementation TCJSUtil

+ (void)load {
    [TCJSModule registerGlobalModuleNamed:@"util" withBlock:^TCJSModule *(JSContext *context) {
        NSString *jsImplPath = [[NSBundle bundleForClass:TCJSUtil.class] pathForResource:@"TCJSUtils" ofType:@"js"];
        TCJSModule *module = [[TCJSModule alloc] initWithScriptContentsOfFile:jsImplPath];
        module.exports[@"isUndefined"] = ^(JSValue *value) {
            return value.isUndefined;
        };
        module.exports[@"isNull"] = ^(JSValue *value) {
            return value.isNull;
        };
        module.exports[@"isNullOrUndefined"] = ^(JSValue *value) {
            return value.isNull || value.isUndefined;
        };
        module.exports[@"isBoolean"] = ^(JSValue *value) {
            return value.isBoolean;
        };
        module.exports[@"isNumber"] = ^(JSValue *value) {
            return value.isNumber;
        };
        module.exports[@"isString"] = ^(JSValue *value) {
            return value.isString;
        };
        module.exports[@"isObject"] = ^(JSValue *value) {
            return value.isObject;
        };
        module.exports[@"format"] = ^NSString *() {
            return [TCJSUtil format];
        };
        module.exports[@"inspect"] = ^NSString *(JSValue *jsValue) {
            return [TCJSUtil inspect:jsValue];
        };
        if ([module.exports respondsToSelector:@selector(isArray)]) {
            module.exports[@"isArray"] = ^(JSValue *value) {
                return value.isArray;
            };
        }
        if ([module.exports respondsToSelector:@selector(isDate)]) {
            module.exports[@"isDate"] = ^(JSValue *value) {
                return value.isDate;
            };
        }

        return module;
    }];
}

+ (NSString *)format {
    NSArray *arguments = [JSContext currentArguments];

    if (arguments.count == 0) {
        return @"";
    }

    JSValue *firstValue = arguments[0];
    if (firstValue.isString) {
        NSString *format = firstValue.toString;
        NSMutableString *result = [NSMutableString string];
        NSArray *formatArguments = [arguments subarrayFromIndex:1];

        NSUInteger __block currentFormatUnitIndex = 0;
        NSUInteger __block lastSourceIndex = 0;
        [format enumerateOccurrencesOfString:@"%" withBlock:^(NSUInteger position, BOOL *stop) {
            // Check if this is a '%' in tail.
            if ((*stop = (position+1 >= format.length ||
                          currentFormatUnitIndex >= formatArguments.count))) {
                return;
            }

            JSValue *formatContentValue = formatArguments[currentFormatUnitIndex++];
            NSString *formatContentString = nil;
            unichar formatUnit = [format characterAtIndex:position+1];
            BOOL shouldUpdateLastUnitIndex = NO;
            switch (formatUnit) {
                case 's': {
                    formatContentString = [self inspect:formatContentValue];
                    shouldUpdateLastUnitIndex = YES;
                    break;
                }
                case 'd': {
                    if (formatContentValue.isNumber) {
                        formatContentString = formatContentValue.toNumber.stringValue;
                    } else {
                        formatContentString = @"NaN";
                    }
                    shouldUpdateLastUnitIndex = YES;
                    break;
                }
                case 'j': {
                    @try {
                        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:formatContentValue.toObject
                                                                           options:0
                                                                             error:nil];
                        formatContentString = [[NSString alloc] initWithData:jsonData
                                                                    encoding:NSUTF8StringEncoding];
                    } @catch (NSException *e) {
                        formatContentString = @"undefined";
                    }
                    shouldUpdateLastUnitIndex = YES;
                    break;
                }
                default:
                    break;
            }

            if (shouldUpdateLastUnitIndex) {
                [result appendString:[format substringWithRange:NSMakeRange(lastSourceIndex,
                                                                            position - lastSourceIndex)]];
                lastSourceIndex = position+2;
            }
            if (formatContentString) {
                [result appendString:formatContentString];
            }
        }];

        if (lastSourceIndex < format.length) {
            [result appendString:[format substringFromIndex:lastSourceIndex]];
        }

        if (currentFormatUnitIndex < formatArguments.count) {
            [[formatArguments subarrayFromIndex:currentFormatUnitIndex]
             enumerateObjectsUsingBlock:^(JSValue *value, NSUInteger idx, BOOL *stop) {
                 [result appendFormat:@" %@", [self inspect:value]];
             }];
        }

        return result;
    } else {
        NSMutableString *result = [NSMutableString string];
        [arguments enumerateObjectsUsingBlock:^(JSValue *value, NSUInteger idx, BOOL *stop) {
            if (idx != 0) {
                [result appendString:@" "];
            }
            [result appendFormat:@"%@", [self inspect:value]];
        }];
        return [NSString stringWithString:result];
    }

    return nil;
}

+ (NSString *)inspect:(JSValue *)jsValue {
    NSString *result;
    if (jsValue.isObject) {
        result = [jsValue.toObject description];
    } else if (jsValue.isBoolean) {
        result = jsValue.toBool ? @"true" : @"false";
    } else {
        result = jsValue.toString;
    }
    return [result stringByReplacingCharactersFromSet:[NSCharacterSet newlineCharacterSet] withString:@""];
}

@end
