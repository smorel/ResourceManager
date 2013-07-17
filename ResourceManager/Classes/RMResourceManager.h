//
//  RMResourceManager.h
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-16.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString* RMResourceManagerFileDidUpdateNotification;
extern NSString* RMResourceManagerApplicationFullPathKey;
extern NSString* RMResourceManagerRelativePathKey;
extern NSString* RMResourceManagerMostRecentPathKey;

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

/** Initialize a newly created resource manager object to manage sync using dropbox and the local file system.
 */
- (id)initWithAppKey:(NSString*)appKey secret:(NSString*)secret dropboxFolder:(NSString*)folder localResourcesDirectory:(NSString*)localResourcesDirectory;

/** Initialize a newly created resource manager object to manage sync using dropbox only.
 */
- (id)initWithAppKey:(NSString*)appKey secret:(NSString*)secret dropboxFolder:(NSString*)folder;

/** Initialize a newly created resource manager object to manage sync using the local file system only.
 */
- (id)initWithLocalResourcesDirectory:(NSString*)localResourcesDirectory;

/******************************************************
 Managing Singleton
 *****************************************************/

/** Sets the resource manager that will manage sync.
 */
+ (void)setSharedManager:(RMResourceManager*)manager;

/** Get the shared manager.
 */
+ (RMResourceManager*)sharedManager;

/******************************************************
 Authentificating withDropbox
 *****************************************************/

/** Forward the open application with url event to the dropbox account After authentification.
 */
- (void)handleApplication:(UIApplication *)application openURL:(NSURL *)url;

/** Forward the open application didFinishLaunchingWithOptions event to the dropbox account for authentification.
 */
- (void)handleApplication:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;


/******************************************************
 Customizing the resource manager
 *****************************************************/

/** default value is 3 seconds.
 */
@property (nonatomic, assign) NSTimeInterval pullingTimeInterval;


/******************************************************
 Accessing resource files
 *****************************************************/

- (NSString *)pathForResource:(NSString *)name ofType:(NSString *)ext;

@end
