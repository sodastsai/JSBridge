//
//  TCJSDataBuffer.m
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

#import "TCJSDataBuffer.h"
#import "TCJSUtils.h"
#import "TCJSJavaScriptContext.h"
#import <BenzeneFoundation/BenzeneFoundation.h>

@protocol TCJSDataBuffer <JSExport>

+ (instancetype)create;
+ (instancetype)fromHexString:(NSString *)string;
+ (instancetype)fromByteArray:(NSArray<NSNumber *> *)bytes;

JSExportAs(subDataBuffer, - (nullable instancetype)subDataBufferFromIndex:(NSUInteger)start length:(NSUInteger)length);
- (instancetype)copyAsNewDataBuffer;

@property (nonatomic, readwrite) NSUInteger length;

// Content
@property (nonatomic, readonly) NSString *hexString;
- (JSValue *)byte;
- (BOOL)equal:(TCJSDataBuffer *)dataBuffer;

- (void)append:(TCJSDataBuffer *)dataBuffer;
JSExportAs(delete, - (void)deleteBytesFromIndex:(NSUInteger)start length:(NSUInteger)length);
JSExportAs(insert, - (void)insertDataBuffer:(TCJSDataBuffer *)dataBuffer atIndex:(NSUInteger)index);

@end

@interface TCJSDataBuffer () <TCJSDataBuffer, TCJSJavaScriptContextExtension>

@end

@implementation TCJSDataBuffer

+ (void)load {
    TCJSJavaScriptContextRegisterExtension(self);
}

+ (void)loadExtensionForJSContext:(JSContext *)context {
    context[@"DataBuffer"] = self;
}

+ (instancetype)create {
    NSArray<JSValue *> *arguments = [JSContext currentArguments];
    return [[TCJSDataBuffer alloc] initWithLength:arguments.firstObject.toNumber.unsignedIntegerValue];
}

+ (instancetype)fromHexString:(NSString *)string {
    return [[TCJSDataBuffer alloc] initWithData:[[NSData dataWithHexString:string] mutableCopy]];
}

+ (instancetype)fromByteArray:(NSArray<NSNumber *> *)bytes {
    return [[TCJSDataBuffer alloc] initWithData:[[NSData dataWithByteArray:bytes] mutableCopy]];
}

#pragma mark - Object Lifecycle

- (instancetype)init {
    return self = [self initWithLength:0];
}

- (instancetype)initWithLength:(NSUInteger)length {
    return self = [self initWithData:[NSMutableData dataWithLength:length]];
}

- (instancetype)initWithData:(NSMutableData *)data {
    if (self = [super init]) {
        _data = data;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:TCJSDataBuffer.class] ? [self isEqualToDataBuffer:object] : NO;
}

- (BOOL)isEqualToDataBuffer:(TCJSDataBuffer *)dataBuffer {
    return [self.data isEqualToData:dataBuffer.data];
}

- (NSUInteger)hash {
    return self.data.hash;
}

#pragma mark - Properties

- (NSUInteger)length {
    return self.data.length;
}

- (void)setLength:(NSUInteger)length {
    self.data.length = length;
}

#pragma mark - Methods

- (JSValue *)byte {
    JSContext *context = [JSContext currentContext];
    NSArray<JSValue *> *arguments = [JSContext currentArguments];

    if (arguments.count == 0) {
        // Return bytes array
        NSMutableArray<NSNumber *> *buffer = [NSMutableArray arrayWithCapacity:self.length];
        for (NSUInteger i=0; i<self.length; ++i) {
            buffer[i] = @(((uint8_t *)self.data.bytes)[i]);
        }
        return [JSValue valueWithObject:[NSArray arrayWithArray:buffer] inContext:context];
    }

    // Indexed operation ...
    // Get index
    if (!arguments[0].isNumber) {
        NSString *message = BFFormatString(@"Got unexpected argument type %@ at 0",
                                           [TCJSUtil toString:arguments[0] context:context]);
        context.exception = [JSValue valueWithNewErrorFromMessage:message inContext:context];
        return nil;
    }
    NSUInteger idx = arguments[0].toNumber.unsignedIntegerValue;
    if (idx >= self.data.length) {
        NSString *message = BFFormatString(@"Out of bound. (0..%ld)", self.data.length-1);
        context.exception = [JSValue valueWithNewErrorFromMessage:message inContext:context];
        return nil;
    }

    if (arguments.count == 1) {
        // Get
        return [JSValue valueWithUInt32:((uint8_t *)self.data.bytes)[idx] inContext:context];
    } else {
        // Set
        BOOL validValue = NO;
        uint8_t value = 0;
        if (arguments[1].isString) {
            NSScanner *scanner = [NSScanner scannerWithString:arguments[1].toString];
            unsigned int _value = 0;
            if ((validValue = [scanner scanHexInt:&_value] && scanner.atEnd && _value < 256)) {
                value = (uint8_t)_value;
            }
        } else if (arguments[1].isNumber) {
            NSInteger _value = arguments[1].toNumber.integerValue;
            if ((validValue = _value < 256)) {
                value = (uint8_t)_value;
            }
        }
        if (!validValue) {
            context.exception = [JSValue valueWithNewErrorFromMessage:@"Expected number from 0 to 255 for argument 1"
                                                            inContext:context];
        } else {
            ((uint8_t *)self.data.bytes)[idx] = value;
        }
        return nil;
    }
}

- (NSString *)hexString {
    return [BFHash hexdigestStringFromData:self.data];
}

- (BOOL)equal:(TCJSDataBuffer *)dataBuffer {
    return [self isEqual:dataBuffer];
}

- (void)append:(TCJSDataBuffer *)dataBuffer {
    [self.data appendData:dataBuffer.data];
}

- (instancetype)subDataBufferFromIndex:(NSUInteger)start length:(NSUInteger)length {
    if (start+length > self.data.length) {
        NSString *message = BFFormatString(@"Out of bound. (0..%ld)", self.data.length-1);
        JSContext *context = [JSContext currentContext];
        context.exception = [JSValue valueWithNewErrorFromMessage:message inContext:context];
        return nil;
    }
    return [[TCJSDataBuffer alloc] initWithData:[[self.data subdataWithRange:NSMakeRange(start, length)] mutableCopy]];
}

- (instancetype)copyAsNewDataBuffer {
    return [[TCJSDataBuffer alloc] initWithData:[self.data mutableCopy]];
}

- (void)deleteBytesFromIndex:(NSUInteger)start length:(NSUInteger)length {
    if (start+length > self.data.length) {
        NSString *message = BFFormatString(@"Out of bound. (0..%ld)", self.data.length-1);
        JSContext *context = [JSContext currentContext];
        context.exception = [JSValue valueWithNewErrorFromMessage:message inContext:context];
        return;
    }

    [self.data replaceBytesInRange:NSMakeRange(start, length) withBytes:NULL length:0];
}

- (void)insertDataBuffer:(TCJSDataBuffer *)dataBuffer atIndex:(NSUInteger)index {
    if (index >= self.data.length) {
        NSString *message = BFFormatString(@"Out of bound. (0..%ld)", self.data.length-1);
        JSContext *context = [JSContext currentContext];
        context.exception = [JSValue valueWithNewErrorFromMessage:message inContext:context];
        return;
    }
    [self.data replaceBytesInRange:NSMakeRange(index, 0) withBytes:dataBuffer.data.bytes length:dataBuffer.data.length];
}

@end
