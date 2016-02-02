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
        TCJSModule *module = [[TCJSModule alloc] initWithContext:context];
        module.exports[@"toString"] = ^(JSValue *obj) {
            return [TCJSUtil toString:obj context:[JSContext currentContext]];
        };
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
        module.exports[@"isFunction"] = ^(JSValue *value) {
            return [TCJSUtil isFunction:value context:[JSContext currentContext]];
        };
        module.exports[@"isError"] = ^(JSValue *value) {
            return [TCJSUtil isError:value context:[JSContext currentContext]];
        };
        module.exports[@"isRegExp"] = ^(JSValue *value) {
            return [TCJSUtil isRegExp:value context:[JSContext currentContext]];
        };
        module.exports[@"isArray"] = ^(JSValue *value) {
            return ([value respondsToSelector:@selector(isArray)] ?
                    value.isArray :
                    [TCJSUtil isArray:value context:[JSContext currentContext]]);
        };
        module.exports[@"isDate"] = ^(JSValue *value) {
            return ([value respondsToSelector:@selector(isDate)] ?
                    value.isDate :
                    [TCJSUtil isDate:value context:[JSContext currentContext]]);
        };

        module.exports[@"format"] = ^NSString *() {
            return [TCJSUtil format];
        };
        module.exports[@"inspect"] = ^NSString *(JSValue *jsValue) {
            return [TCJSUtil inspect:jsValue];
        };

        module.exports[@"enumerate"] = ^NSArray<NSString *> *(JSValue *jsValue) {
            return [TCJSUtil arrayWithPropertiesOfValue:jsValue context:[JSContext currentContext]];
        };
        module.exports[@"extend"] = ^JSValue *_Nullable() {
            NSArray<JSValue *> *arguments = [JSContext currentArguments];
            if (arguments.count <= 1) {
                return arguments.firstObject;
            } else {
                return [TCJSUtil extends:arguments.firstObject
                             withObjects:[arguments subarrayFromIndex:1]
                                 context:[JSContext currentContext]];
            }
        };

        module.exports[@"inherits"] = ^JSValue *_Nullable(JSValue *Constructor, JSValue *SuperConstructor) {
            return [TCJSUtil inherits:Constructor
                 withSuperConstructor:SuperConstructor
                              context:[JSContext currentContext]];
        };

        return module;
    }];
}

+ (NSString *)toString:(JSValue *)obj context:(nonnull JSContext *)context {
    return [[context evaluateScript:
             @"(function() {\n"
             @"    return function(obj) {\n"
             @"        return Object.prototype.toString.call(obj);\n"
             @"    };\n"
             @"})();"] callWithArguments:@[obj]].toString;
}

+ (BOOL)isFunction:(JSValue *)obj context:(nonnull JSContext *)context {
    return [[self toString:obj context:context] isEqualToString:@"[object Function]"];
}

+ (BOOL)isArray:(JSValue *)obj context:(nonnull JSContext *)context {
    return ([obj respondsToSelector:@selector(isArray)] ?
            obj.isArray :
            [[self toString:obj context:context] isEqualToString:@"[object Array]"]);
}

+ (BOOL)isDate:(JSValue *)obj context:(nonnull JSContext *)context {
    return ([obj respondsToSelector:@selector(isDate)] ?
            obj.isDate :
            [[self toString:obj context:context] isEqualToString:@"[object Date]"]);
}

+ (BOOL)isError:(JSValue *)obj context:(nonnull JSContext *)context {
    return [[self toString:obj context:context] isEqualToString:@"[object Error]"];
}

+ (BOOL)isRegExp:(JSValue *)obj context:(nonnull JSContext *)context {
    return [[self toString:obj context:context] isEqualToString:@"[object RegExp]"];
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

+ (NSArray<NSString *> *)arrayWithPropertiesOfValue:(JSValue *)jsValue context:(JSContext *)context {
    NSMutableArray *result = [[NSMutableArray alloc] init];

    id value = jsValue.toObject;
    if ([value conformsToProtocol:@protocol(JSExport)] && [value conformsToProtocol:@protocol(TCJSUtilEnumerate)]) {
        return [[value class] enumerableJSProperties];
    } else {
        return [context[@"Object"] invokeMethod:@"keys" withArguments:@[jsValue]].toArray;
    }

    return [NSArray arrayWithArray:result];
}

+ (JSValue *)extends:(JSValue *)object withObjects:(NSArray<JSValue *> *)objects context:(JSContext *)context {
    NSMutableArray *arguments = [[NSMutableArray alloc] initWithCapacity:objects.count+1];
    [arguments addObject:object];
    [arguments addObjectsFromArray:objects];
    return [context[@"Object"] invokeMethod:@"assign" withArguments:arguments];
}

+ (void)defineProperty:(NSString *)property
            enumerable:(BOOL)enumerable
          configurable:(BOOL)configurable
              writable:(BOOL)writable
                 value:(id)value
                getter:(nullable id _Nullable(^)(void))getter
                setter:(nullable void(^)(id _Nullable))setter
              forValue:(JSValue *)jsValue {
    NSMutableDictionary *descriptor = [@{
        JSPropertyDescriptorEnumerableKey: @(enumerable),
        JSPropertyDescriptorConfigurableKey: @(configurable),
    } mutableCopy];
    if (value) {
        descriptor[JSPropertyDescriptorValueKey] = value;
    }
    if (getter) {
        descriptor[JSPropertyDescriptorGetKey] = getter;
    }
    if (setter) {
        descriptor[JSPropertyDescriptorSetKey] = setter;
    }
    if (!getter && !setter) {
        descriptor[JSPropertyDescriptorWritableKey] = @(writable);
    }
    [jsValue defineProperty:property descriptor:descriptor];
}

+ (void)defineProperty:(NSString *)property
              forValue:(JSValue *)value
 withNativeObjectNamed:(NSString *)nativeObjectName
               keyPath:(NSString *)keyPath
              readonly:(BOOL)readonly {
    [self defineProperty:property
              enumerable:YES
            configurable:NO
                writable:!readonly
                   value:nil
                  getter:^id _Nullable{
                      return [[[JSContext currentThis][nativeObjectName] toObject] valueForKeyPath:keyPath];
                  } setter:readonly ? nil : ^(id _Nullable _value) {
                      [[[JSContext currentThis][nativeObjectName] toObject] setValue:_value forKey:keyPath];
                  } forValue:value];
}

+ (void)defineReadonlyProperty:(NSString *)property forJSValue:(JSValue *)jsValue withValue:(id)value {
    [self defineProperty:property
              enumerable:YES configurable:NO writable:NO
                   value:value getter:nil setter:nil
                forValue:jsValue];
}

+ (JSValue *)inherits:(JSValue *)constructor
 withSuperConstructor:(JSValue *)superConstructor
              context:(JSContext *)context {
    return [[context evaluateScript:
             @"(function() {\n"
             @"    return function(c, sc) {\n"
             @"        c.super_ = sc;\n"
             @"        return Object.setPrototypeOf(c.prototype, sc.prototype);\n"
             @"    };\n"
             @"})();"] callWithArguments:@[constructor, superConstructor]];
}

@end

#pragma mark - Constructor Builder

@interface TCJSConstructorBuilder ()

@property (nonatomic, strong, readonly) NSString *name;

@property (nonatomic, strong) NSMutableArray<BFPair<NSString *, NSString *> *> *properties;
@property (nonatomic, strong) NSMutableArray<NSString *> *superArguments;

@end

@implementation TCJSConstructorBuilder

+ (instancetype)constructorBuilderWithName:(NSString *)name {
    return [[TCJSConstructorBuilder alloc] initWithName:name];
}

- (instancetype)initWithName:(NSString *)name {
    if (self = [super init]) {
        _name = name;
        _properties = [[NSMutableArray alloc] init];
        _superArguments = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addProperty:(nullable NSString *)property argumentName:(NSString *)argument passToSuper:(BOOL)toSuper {
    [self.properties addObject:[BFPair<NSString *, NSString *> pairWithObject:property
                                                                    andObject:argument]];
    if (toSuper) {
        [self.superArguments addObject:argument];
    }
}

- (NSArray<NSString *> *)constructorArguments {
    NSMutableArray<NSString *> *result = [[NSMutableArray alloc] initWithCapacity:self.properties.count];
    [self.properties enumerateObjectsUsingBlock:^(BFPair<NSString *,NSString *> *pair, NSUInteger idx, BOOL *stop) {
        [result addObject:pair.secondObject];
    }];
    return [NSArray arrayWithArray:result];
}

- (NSString *)propertySetupStringWithPadding:(NSUInteger)padding {
    NSMutableString *paddingString = [[NSMutableString alloc] initWithCapacity:padding];
    for (NSUInteger i=0; i<padding; i++) {
        [paddingString appendString:@" "];
    }

    NSMutableArray<NSString *> *result = [[NSMutableArray alloc] initWithCapacity:self.properties.count];
    [self.properties enumerateObjectsUsingBlock:^(BFPair<NSString *,NSString *> *pair, NSUInteger idx, BOOL *stop) {
        if (pair.firstObject) {
            [result addObject:BFFormatString(@"%@this.%@ = %@;", paddingString, pair.firstObject, pair.secondObject)];
        }
    }];
    return [result componentsJoinedByString:@"\n"];
}

- (NSString *)script {
    NSMutableString *script = [NSMutableString stringWithFormat:
                               @"function %@(%@) {\n"
                               @"    if (typeof this.constructor.super_ !== 'undefined' && \n"
                               @"        this.constructor.super_ !== arguments.callee) {\n"
                               @"        this.constructor.super_.apply(this, [%@]);\n"
                               @"    }\n"
                               @"%@\n"
                               @"}",
                               self.name,
                               [self.constructorArguments componentsJoinedByString:@", "],
                               [self.superArguments componentsJoinedByString:@", "],
                               [self propertySetupStringWithPadding:4]];
    return [NSString stringWithString:script];
}

- (JSValue *)buildWithContext:(JSContext *)context {
    return [context evaluateScript:[NSString stringWithFormat:@"(function() { return %@; })();", self.script]];
}

- (JSValue *)buildWithModule:(TCJSModule *)module context:(JSContext *)context {
    return [module evaluateScript:[NSString stringWithFormat:@"return %@;", self.script] sourceURL:nil context:context];
}

@end
