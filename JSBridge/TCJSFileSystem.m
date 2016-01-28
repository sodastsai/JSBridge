//
//  TCJSFileSystem.m
//  JSBridge
//
//  Created by sodas on 1/28/16.
//  Copyright © 2016 JSBridge. All rights reserved.
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
