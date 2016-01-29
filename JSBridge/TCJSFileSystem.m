//
//  TCJSFileSystem.m
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

#import "TCJSFileSystem.h"
#import <BenzeneFoundation/BenzeneFoundation.h>
#import "TCJSDispatch.h"
#import "TCJSUtils.h"
#import "TCJSDataBuffer.h"

@protocol TCJSFileSystem <JSExport>

- (BOOL)existsSync:(NSString *)path;
JSExportAs(exists, - (void)exists:(NSString *)path callback:(JSValue *)callback);
- (BOOL)isDirectorySync:(NSString *)path;
JSExportAs(isDirectory, - (void)isDirectory:(NSString *)path callback:(JSValue *)callback);

- (void)readFile;
- (void)writeFile;

@end

@interface TCJSFileSystem () <TCJSFileSystem>

@end

@implementation TCJSFileSystem

+ (instancetype)defaultFileSystem {
    static TCJSFileSystem *fileSystem;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fileSystem = [[TCJSFileSystem alloc] init];
    });
    return fileSystem;
}

+ (void)load {
    [TCJSModule registerGlobalModuleNamed:@"fs" withBlock:^TCJSModule *(JSContext *context) {
        TCJSModule *module = [[TCJSModule alloc] init];
        module.exports = [JSValue valueWithObject:[TCJSFileSystem defaultFileSystem]
                                        inContext:[JSContext currentContext]];
        return module;
    }];
}

#pragma mark - File Permission

- (BOOL)hasPermissionToReadFileAtPath:(NSString *)path {
    if ([self.delegate respondsToSelector:@selector(context:hasPermissionToReadFileAtPath:)]) {
        return [self.delegate context:[JSContext currentContext] hasPermissionToReadFileAtPath:path];
    }
    return NO;
}

- (BOOL)hasPermissionToWriteFileAtPath:(NSString *)path {
    if ([self.delegate respondsToSelector:@selector(context:hasPermissionToWriteFileAtPath:)]) {
        return [self.delegate context:[JSContext currentContext] hasPermissionToWriteFileAtPath:path];
    }
    return NO;
}

- (BOOL)hasPermissionToDeleteFileAtPath:(NSString *)path {
    if ([self.delegate respondsToSelector:@selector(context:hasPermissionToDeleteFileAtPath:)]) {
        return [self.delegate context:[JSContext currentContext] hasPermissionToDeleteFileAtPath:path];
    }
    return NO;
}

#pragma mark - Method

- (BOOL)existsSync:(NSString *)path {
    return [self hasPermissionToReadFileAtPath:path] && [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (void)exists:(NSString *)path callback:(JSValue *)callback {
    [TCJSDispatchManager asyncExecute:^NSArray *(JSContext *context) {
        return @[@([self existsSync:path])];
    } callback:callback];
}

- (BOOL)isDirectorySync:(NSString *)path {
    BOOL isDirectory;
    return ([self hasPermissionToReadFileAtPath:path] &&
            [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] &&
            isDirectory);
}

- (void)isDirectory:(NSString *)path callback:(JSValue *)callback {
    [TCJSDispatchManager asyncExecute:^NSArray *(JSContext *context) {
        return @[@([self isDirectorySync:path])];
    } callback:callback];
}

- (void)readFile {
    JSContext *context = [JSContext currentContext];
    NSArray<JSValue *> *arguments = [JSContext currentArguments];
    JSValue *filenameValue;
    JSValue *callback;
    if (arguments.count == 0) {
        // pass ...
    } else if (arguments.count == 1) {
        filenameValue = arguments[0];
    } else {
        filenameValue = arguments[0];
        callback = arguments[1];
    }
    if (!filenameValue.isString) {
        context.exception = [JSValue valueWithNewErrorFromMessage:@"filename must be a string" inContext:context];
        return;
    }

    NSString *filename = filenameValue.toString;
    [TCJSDispatchManager asyncExecute:^NSArray *(JSContext *context) {
        if ([self hasPermissionToReadFileAtPath:filename]) {
            NSError *error;
            NSData *data = [[NSData alloc] initWithContentsOfFile:filename options:0 error:&error];
            if (data) {
                TCJSDataBuffer *dataBuffer = [[TCJSDataBuffer alloc] initWithData:[data mutableCopy]];
                return @[dataBuffer, [JSValue valueWithNullInContext:context]];
            } else {
                JSValue *errorValue = [JSValue valueWithNewErrorFromMessage:error.localizedDescription
                                                                  inContext:context];
                return @[[JSValue valueWithNullInContext:context], errorValue];
            }
        } else {
            JSValue *error = [JSValue valueWithNewErrorFromMessage:@"Permission denied" inContext:context];
            return @[[JSValue valueWithNullInContext:context], error];
        }
    } callback:callback];
}

- (void)writeFile {
    JSContext *context = [JSContext currentContext];
    NSArray<JSValue *> *arguments = [JSContext currentArguments];
    JSValue *filenameValue;
    JSValue *dataBufferValue;
    JSValue *callback;
    if (arguments.count <= 1) {
        filenameValue = arguments.firstObject;
    } else if (arguments.count == 2) {
        filenameValue = arguments[0];
        dataBufferValue = arguments[1];
    } else if (arguments.count >= 3) {
        filenameValue = arguments[0];
        dataBufferValue = arguments[1];
        callback = arguments[2];
    }
    if (!filenameValue.isString) {
        context.exception = [JSValue valueWithNewErrorFromMessage:@"filename must be a string" inContext:context];
        return;
    }
    TCJSDataBuffer *dataBuffer = [dataBufferValue toObjectOfClass:TCJSDataBuffer.class];
    if (!dataBuffer) {
        context.exception = [JSValue valueWithNewErrorFromMessage:@"dataBuffer must be a DataBuffer" inContext:context];
        return;
    }

    NSString *filename = filenameValue.toString;
    [TCJSDispatchManager asyncExecute:^NSArray *(JSContext *context) {
        if ([self hasPermissionToWriteFileAtPath:filename]) {
            NSError *error;
            if ([dataBuffer.data writeToFile:filename options:NSDataWritingAtomic error:&error]) {
                return @[[JSValue valueWithNullInContext:context]];
            } else {
                JSValue *errorValue = [JSValue valueWithNewErrorFromMessage:error.localizedDescription
                                                                  inContext:context];
                return @[errorValue];
            }
        } else {
            JSValue *error = [JSValue valueWithNewErrorFromMessage:@"Permission denied" inContext:context];
            return @[error];
        }
    } callback:callback];
}

@end
