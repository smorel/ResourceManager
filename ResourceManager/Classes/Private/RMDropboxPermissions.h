//
//  RMDropboxPermissions.h
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-17.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "RWWeakLinkedDBAccountInfo.h"

@interface RMDropboxPermissions : NSObject
@property(nonatomic, copy) void(^availabilityBlock)(BOOL available);

- (id)initWithAccount:(RWWeakLinkedDBAccountInfo*)account;

- (BOOL)arePermissionsAvailable;
- (BOOL)canAccesFilesInDirectory:(NSString*)directory;
- (BOOL)canAccessFilesWithExtension:(NSString*)extension;

@end
