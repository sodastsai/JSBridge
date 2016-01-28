//
//  TCJSFileSystem.h
//  JSBridge
//
//  Created by sodas on 1/28/16.
//  Copyright © 2016 JSBridge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <TCJSBridge/TCJSModule.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TCJSFileSystemDelegate;

@protocol TCJSFileSystem <JSExport>

- (BOOL)exists:(NSString *)path;

@end

@interface TCJSFileSystem : NSObject <TCJSFileSystem>

+ (instancetype)defaultFileSystem;

@property (nonatomic, weak, nullable, readwrite) id<TCJSFileSystemDelegate> delegate;

@end

@protocol TCJSFileSystemDelegate <NSObject>

@optional - (BOOL)context:(JSContext *)context hasPermissionToReadFileAtPath:(NSString *)path;
@optional - (BOOL)context:(JSContext *)context hasPermissionToWriteFileAtPath:(NSString *)path;
@optional - (BOOL)context:(JSContext *)context hasPermissionToDeleteFileAtPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
