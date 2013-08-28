//
//  RMFileSystem.h
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-16.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import "RMResourceRepository.h"


//RMResourceManagerDidEndUpdatingResourcesNotification
extern NSString* RMResourceManagerDidEndUpdatingResourcesNotification;
extern NSString* RMResourceManagerUpdatedResourcesPathKey;

/**
 [[NSNotificationCenter defaultCenter]addObserverForName:RMResourceManagerDidEndUpdatingResourcesNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
 NSArray* updatedFiles = [notification.userInfo objectForKey:RMResourceManagerUpdatedResourcesPathKey];
 for(NSDictionary* file in updatedFiles){
 NSString* relativePath          = [file objectForKey:RMResourceManagerRelativePathKey];
 NSString* applicationBundlePath = [file objectForKey:RMResourceManagerApplicationBundlePathKey];
 NSString* mostRecentPath        = [file objectForKey:RMResourceManagerMostRecentPathKey];
 
 //DO Something
 }
 }];
 */

//-------------------

//RMResourceManagerFileDidUpdateNotification
extern NSString* RMResourceManagerFileDidUpdateNotification;
extern NSString* RMResourceManagerApplicationBundlePathKey;
extern NSString* RMResourceManagerRelativePathKey;
extern NSString* RMResourceManagerMostRecentPathKey;

/**
 [[NSNotificationCenter defaultCenter]addObserverForName:RMResourceManagerFileDidUpdateNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
 NSString* relativePath          = [notification.userInfo objectForKey:RMResourceManagerRelativePathKey];
 NSString* applicationBundlePath = [notification.userInfo objectForKey:RMResourceManagerApplicationBundlePathKey];
 NSString* mostRecentPath        = [notification.userInfo objectForKey:RMResourceManagerMostRecentPathKey];
 //DO Something
 }];
 */

//-------------------


@interface RMFileSystem : NSObject

@property(nonatomic, retain, readonly) NSSet* repositories;

/** 
 */
- (id)initWithRepositories:(NSSet*)repositories;


/**
 */
+ (NSString*)relativePathForResourceWithPath:(NSString*)path;

/** This will return the path of the most recent file between the specified application file and the potentially downloaded file from dropbox.
 */
- (NSString*)pathForResourceAtPath:(NSString*)applicationBundlePath;

/** This will return the path of the file from dropbox that matches name ext subpath localizationName.
 */
- (NSString *)pathForResource:(NSString *)name ofType:(NSString *)ext forLocalization:(NSString *)localizationName;

/** Returns the most recent paths between local cache and application bundle for files with the specified extension and the specified localization
 */
- (NSArray *)pathsForResourcesWithExtension:(NSString *)ext localization:(NSString *)localizationName;

@end
