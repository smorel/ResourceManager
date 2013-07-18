//
//  RMResourceManager.h
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-16.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import <UIKit/UIKit.h>

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

/** The resource Manager will manage the sync between your application resources and a dropbox repository and/or a directory
 on your computer's file system.
 Using the dropbox sync allow to synchronize resource modifications to your device.
 Using a local repository allow to synchronize resource modifications in the simulator only.
 
 Resources from dropbox will get store in your application's cache directory. When changes occurs on dropbox or your local directory,
 The resource manager will look for the last modified file from dropbox/local file system and the applications bundle.
 The newer is the winner and the resource manager will fire a notification for you to reload your UI or data models using this new file.
 
 https://www.dropbox.com/developers/core/sdks/ios
 
 */
@interface RMResourceManager : NSObject

/******************************************************
 Initializing Manager
 *****************************************************/

/** Initialize a newly created resource manager object to manage sync using dropbox.
 */
- (id)initWithAppKey:(NSString*)appKey secret:(NSString*)secret dropboxFolder:(NSString*)folder;


/******************************************************
 Managing Singleton
 *****************************************************/

/** Sets the resource manager that will manage sync.
 */
+ (void)setSharedManager:(RMResourceManager*)manager;

/** return YES if the shared manager has been setup.
 */
+ (BOOL)isResourceManagerConnected;

/******************************************************
 Authentificating withDropbox
 *****************************************************/

/** Forward the open application with url event to the dropbox account After authentification.
 */
+ (void)handleApplication:(UIApplication *)application openURL:(NSURL *)url;

/** Forward the open application didFinishLaunchingWithOptions event to the dropbox account for authentification.
 */
+ (void)handleApplication:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;


/******************************************************
 Customizing the resource manager
 *****************************************************/

/** default value is 3 seconds.
 */
+ (void)setPullingInterval:(NSTimeInterval)interval;

/******************************************************
 Accessing resource files
 *****************************************************/

+ (NSString *)pathForResource:(NSString *)name ofType:(NSString *)ext;

+ (NSString *)pathForResource:(NSString *)name ofType:(NSString *)ext observer:(id)observer usingBlock:(void(^)(id observer, NSString* path))updateBlock;

+ (NSArray *)pathsForResourcesWithExtension:(NSString *)ext;

+ (NSArray *)pathsForResourcesWithExtension:(NSString *)ext localization:(NSString *)localizationName;

+ (NSArray *)pathsForResourcesWithExtension:(NSString *)ext observer:(id)observer usingBlock:(void(^)(id observer, NSArray* paths))updateBlock;

+ (NSArray *)pathsForResourcesWithExtension:(NSString *)ext localization:(NSString *)localizationName observer:(id)observer usingBlock:(void(^)(id observer, NSArray* paths))updateBlock;

/******************************************************
 Managing update observers
 *****************************************************/

+ (void)addObserverForResourcesWithExtension:(NSString*)ext object:(id)object usingBlock:(void(^)(id observer, NSArray* paths))updateBlock;
+ (void)addObserverForPath:(NSString*)path object:(id)object usingBlock:(void(^)(id observer, NSString* path))updateBlock;
+ (void)removeObserver:(id)object;

/******************************************************
 Managing HUD
 *****************************************************/

/** default value is yes.
 */
+ (void)setHudEnabled:(BOOL)enabled;

/** Sets the title displayed in the hud if hud is enabled.
 */
+ (void)setHudTitle:(NSString*)title;


@end
