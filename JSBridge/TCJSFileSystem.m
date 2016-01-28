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
    [TCJSModule registerGlobalModuleNamed:@"fs" withBlock:^TCJSModule * _Nonnull{
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

- (BOOL)exists:(NSString *)path {
    return [self hasPermissionToReadFileAtPath:path] && [[NSFileManager defaultManager] fileExistsAtPath:path];
}

@end
