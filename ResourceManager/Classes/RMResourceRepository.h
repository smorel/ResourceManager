//
//  RMResourceRepository.h
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-19.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class RMResourceRepository;

/**
 */
@protocol RMResourceRepositoryDelegate <NSObject>

@required

/**
 */
- (void)repository:(RMResourceRepository*)repository didReceiveUpdates:(NSArray*)filePaths revokedAccess:(NSArray*)revokedFilePaths;

/**
 */
- (BOOL)shouldRepository:(RMResourceRepository*)repository updateFileWithRelativePath:(NSString*)filePath modificationDate:(NSDate*)modificationDate;

/**
 */
- (NSString*)repository:(RMResourceRepository*)repository requestStoragePathForFileWithRelativePath:(NSString*)filePath;

/**
 */
- (void)repository:(RMResourceRepository*)repository didNotifyHudWithMessage:(NSString*)message;


@end



/**
*/
@interface RMResourceRepository : NSObject

/**
 */
@property(nonatomic, assign) id<RMResourceRepositoryDelegate> delegate;

/**
 */
- (void)handleApplication:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

/**
 */
- (void)handleApplication:(UIApplication *)application openURL:(NSURL *)url;


//Private implementation for subclasses

/**
 */
- (void)connect;

/**
 */
- (void)disconnect;

/**
 */
- (NSString*)relativePathForResourceWithPath:(NSString*)path;

/**
 */
- (void)notifyHudWitchMessage:(NSString*)message;

@end
