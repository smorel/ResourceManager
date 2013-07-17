//
//  RMPermissions.h
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-17.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RMPermissions : NSObject
@property(nonatomic, copy) void(^availabilityBlock)(BOOL available);

- (BOOL)arePermissionsAvailable;
- (BOOL)canAccesFilesInDirectory:(NSString*)directory;
- (BOOL)canAccessFilesWithExtension:(NSString*)extension;

@end
