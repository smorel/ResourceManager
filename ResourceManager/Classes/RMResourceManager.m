//
//  RMResourceManager.m
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-16.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import "RMResourceManager.h"
#import "RMFileSystem.h"

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <DropboxSDK/DropboxSDK.h>

#import "UIImage+ResourceManager.h"


NSString* RMResourceManagerFileDidUpdateNotification = @"RMResourceManagerFileDidUpdateNotification";
NSString* RMResourceManagerApplicationBundlePathKey  = @"RMResourceManagerApplicationBundlePathKey";
NSString* RMResourceManagerRelativePathKey           = @"RMResourceManagerRelativePathKey";
NSString* RMResourceManagerMostRecentPathKey         = @"RMResourceManagerMostRecentPathKey";

NSString* RMResourceManagerDidEndUpdatingResourcesNotification = @"RMResourceManagerDidEndUpdatingResourcesNotification";
NSString* RMResourceManagerUpdatedResourcesPathKey             = @"RMResourceManagerUpdatedResourcesPathKey";

static RMResourceManager* kSharedManager = nil;

@interface RMResourceManager()<DBSessionDelegate>

@property (nonatomic, retain) DBSession* dbSession;
@property (nonatomic, retain) NSString* dropboxFolder;
@property (nonatomic, retain) RMFileSystem* fileSystem;
@property (nonatomic, assign) NSTimeInterval pullingTimeInterval;

@property (nonatomic, retain) NSMutableDictionary* updateDictionary;           //{ "relativePath" : { "weak NSValue observer" : "updateBlock", ... } , ... }
@property (nonatomic, retain) NSMutableDictionary* updateExtensionsDictionary; //{ "extension" : { "weak NSValue observer" : "updateBlock", ... } , ... }

@end

@implementation RMResourceManager

#pragma mark Managing Singleton

+ (void)setSharedManager:(RMResourceManager*)manager{
    kSharedManager = manager;
}

+ (RMResourceManager*)sharedManager{
    return kSharedManager;
}


#pragma mark Initializing Resource Manager

- (id)initWithAppKey:(NSString*)appKey secret:(NSString*)secret dropboxFolder:(NSString*)folder{
    self = [super init];
    
    self.pullingTimeInterval = 3;
    
    if(appKey && secret){
        DBSession* dbSession = [[DBSession alloc] initWithAppKey:appKey appSecret:secret root:kDBRootDropbox];
        dbSession.delegate = self;
        [DBSession setSharedSession:dbSession];
        
        self.dropboxFolder = folder;
        
        if([[DBSession sharedSession] isLinked]){
            [self startResourceManagement];
        }
    }
    
    return self;
}

- (void)dealloc{
    [self stopResourceManagement];
}

#pragma mark Managing Dropbox Authentification

+ (void)handleApplication:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    RMResourceManager* manager = [RMResourceManager sharedManager];
    if(!manager)
        return;
    
    if (![[DBSession sharedSession] isLinked]) {
        [manager presentsLinkAccountViewController];
    }
}

+ (void)handleApplication:(UIApplication *)application openURL:(NSURL *)url{
    RMResourceManager* manager = [RMResourceManager sharedManager];
    if(!manager)
        return;
    
	if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            [manager startResourceManagement];
        }
    }
}

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId{
    [self presentsLinkAccountViewController];
}

- (void)presentsLinkAccountViewController{
    UIViewController* root = [[[[UIApplication sharedApplication]windows]objectAtIndex:0]rootViewController];
    NSAssert(root,@"Your application's main window has no root view controller.");
 
    [[DBSession sharedSession] linkFromController:root];
}


#pragma mark Managing File System

+ (void)setPullingInterval:(NSTimeInterval)interval{
    RMResourceManager* manager = [RMResourceManager sharedManager];
    if(!manager)
        return;
    
    manager.pullingTimeInterval = interval;
}

- (void)setPullingTimeInterval:(NSTimeInterval)thePullingTimeInterval{
    _pullingTimeInterval = thePullingTimeInterval;
    if(self.fileSystem){
        self.fileSystem.pullingTimeInterval = self.pullingTimeInterval;
    }
}

- (void)startResourceManagement{
    self.fileSystem = [[RMFileSystem alloc]initWithDropboxFolder:self.dropboxFolder];
    self.fileSystem.pullingTimeInterval = self.pullingTimeInterval;
    
    __unsafe_unretained RMResourceManager* bself = self;
    [[NSNotificationCenter defaultCenter]addObserverForName:RMResourceManagerFileDidUpdateNotification object:self.fileSystem queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
        NSString* relativePath          = [notification.userInfo objectForKey:RMResourceManagerRelativePathKey];
        NSString* applicationBundlePath = [notification.userInfo objectForKey:RMResourceManagerApplicationBundlePathKey];
        NSString* mostRecentPath        = [notification.userInfo objectForKey:RMResourceManagerMostRecentPathKey];
        [bself resourceDidUpdateWithRelativePath:relativePath applicationBundlePath:applicationBundlePath mostRecentPath:mostRecentPath];
    }];
    
    [[NSNotificationCenter defaultCenter]addObserverForName:RMResourceManagerDidEndUpdatingResourcesNotification object:self.fileSystem queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
        if([bself.updateExtensionsDictionary count] > 0){
            NSArray* updatedFiles = [notification.userInfo objectForKey:RMResourceManagerUpdatedResourcesPathKey];
            NSMutableSet* updatedFileExtensions = [NSMutableSet set];
            for(NSDictionary* file in updatedFiles){
                NSString* mostRecentPath = [notification.userInfo objectForKey:RMResourceManagerMostRecentPathKey];
                NSString* extension      = [mostRecentPath pathExtension];
                [updatedFileExtensions addObject:extension];
            }
            
            [bself resourcesDidUpdateWithExtensions:updatedFileExtensions];
        }
    }];

}

- (void)stopResourceManagement{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:RMResourceManagerFileDidUpdateNotification object:self.fileSystem];
    self.fileSystem = nil;
}

#pragma mark Managing Resource Paths

+ (NSString *)pathForResource:(NSString *)name ofType:(NSString *)ext observer:(id)observer usingBlock:(void(^)(id observer, NSString* path))updateBlock{
    NSString* path = [self pathForResource:name ofType:ext];
    if(path && updateBlock && observer){
        [RMResourceManager addObserverForPath:path object:observer usingBlock:updateBlock];
    }
    return path;
}

+ (NSString *)pathForResource:(NSString *)name ofType:(NSString *)ext{
    NSString* path = [[NSBundle mainBundle]pathForResource:name ofType:ext];
    
    RMResourceManager* manager = [RMResourceManager sharedManager];
    if(!manager || !manager.fileSystem){
        return path;
    }
    
    if(path){
        return [manager.fileSystem pathForResourceAtPath:path];
    }
    
    //Resource is not embedded in app. Check in the file system for dropbox resource.
    NSString* currentLocale = [[NSLocale preferredLanguages] objectAtIndex:0];
    path = [manager.fileSystem pathForResource:name ofType:ext forLocalization:currentLocale];
    
    if(!path){
        path = [manager.fileSystem pathForResource:name ofType:ext forLocalization:@"en"];
    }
    
    if(!path){
        path = [manager.fileSystem pathForResource:name ofType:ext forLocalization:nil];
    }
    
    return path;
}

+ (NSArray *)pathsForResourcesWithExtension:(NSString *)ext{
    NSString* currentLocale = [[NSLocale preferredLanguages] objectAtIndex:0];
    return [self pathsForResourcesWithExtension:ext localization:currentLocale];
}

+ (NSArray *)pathsForResourcesWithExtension:(NSString *)ext localization:(NSString *)localizationName{
    RMResourceManager* manager = [RMResourceManager sharedManager];
    if(!manager || !manager.fileSystem){
        return [[NSBundle mainBundle]pathsForResourcesOfType:ext inDirectory:nil];
    }
    
    return [manager.fileSystem pathsForResourcesWithExtension:ext localization:localizationName];
}

+ (NSArray *)pathsForResourcesWithExtension:(NSString *)ext observer:(id)observer usingBlock:(void(^)(id observer, NSArray* paths))updateBlock{
    NSArray* paths = [self pathsForResourcesWithExtension:ext];
    if(paths && updateBlock && observer){
        [RMResourceManager addObserverForResourcesWithExtension:ext object:observer usingBlock:updateBlock];
    }
    return paths;
}

+ (NSArray *)pathsForResourcesWithExtension:(NSString *)ext localization:(NSString *)localizationName observer:(id)observer usingBlock:(void(^)(id observer, NSArray* paths))updateBlock{
    NSArray* paths = [self pathsForResourcesWithExtension:ext localization:localizationName];
    if(paths && updateBlock && observer){
        [RMResourceManager addObserverForResourcesWithExtension:ext object:observer usingBlock:updateBlock];
    }
    return paths;
}

#pragma mark Managing Update Observer

//This is not the optimal version we could do here as it requiers to iterate on all dictionary entries ...

+ (void)removeObserver:(id)observer{
    RMResourceManager* manager = [RMResourceManager sharedManager];
    if(!manager || !manager.fileSystem)
        return;
    
    NSValue* observerValue = [NSValue valueWithNonretainedObject:observer];
    for(NSString* relativePath in [manager.updateDictionary allKeys]){
        NSMutableDictionary* observersToUpdateBlocks = [manager.updateDictionary objectForKey:relativePath];
        [observersToUpdateBlocks removeObjectForKey:observerValue];
    }
    
    for(NSString* relativePath in [manager.updateExtensionsDictionary allKeys]){
        NSMutableDictionary* observersToUpdateBlocks = [manager.updateExtensionsDictionary objectForKey:relativePath];
        [observersToUpdateBlocks removeObjectForKey:observerValue];
    }
}

+ (void)addObserverForPath:(NSString*)path object:(id)observer usingBlock:(void(^)(id observer, NSString* path))updateBlock{
    if(!path)
        return;
    
    RMResourceManager* manager = [RMResourceManager sharedManager];
    if(!manager || !manager.fileSystem)
        return;
    
    if(!manager.updateDictionary){
        manager.updateDictionary = [NSMutableDictionary dictionary];
    }
    
    NSString* relativePath = [manager.fileSystem relativePathForPath:path];
    
    NSMutableDictionary* observersToUpdateBlocks = [manager.updateDictionary objectForKey:relativePath];
    if(!observersToUpdateBlocks){
        observersToUpdateBlocks = [NSMutableDictionary dictionary];
        [manager.updateDictionary setObject:observersToUpdateBlocks forKey:relativePath];
    }
    
    NSValue* observerValue = [NSValue valueWithNonretainedObject:observer];
    [observersToUpdateBlocks setObject:[updateBlock copy] forKey:observerValue];
}

+ (void)addObserverForResourcesWithExtension:(NSString*)ext object:(id)observer usingBlock:(void(^)(id observer, NSArray* paths))updateBlock{
    if(!ext)
        return;
    
    RMResourceManager* manager = [RMResourceManager sharedManager];
    if(!manager || !manager.fileSystem)
        return;
    
    if(!manager.updateExtensionsDictionary){
        manager.updateExtensionsDictionary = [NSMutableDictionary dictionary];
    }
    
    NSMutableDictionary* observersToUpdateBlocks = [manager.updateDictionary objectForKey:ext];
    if(!observersToUpdateBlocks){
        observersToUpdateBlocks = [NSMutableDictionary dictionary];
        [manager.updateExtensionsDictionary setObject:observersToUpdateBlocks forKey:ext];
    }
    
    NSValue* observerValue = [NSValue valueWithNonretainedObject:observer];
    [observersToUpdateBlocks setObject:[updateBlock copy] forKey:observerValue];
}

- (void)resourceDidUpdateWithRelativePath:(NSString*)relativePath applicationBundlePath:(NSString*)applicationBundlePath mostRecentPath:(NSString*)mostRecentPath{
    if(!self.updateDictionary)
        return;
    
    NSMutableDictionary* observersToUpdateBlocks = [self.updateDictionary objectForKey:relativePath];
    for(NSValue* observerValue in [observersToUpdateBlocks allKeys]){
        id observer = [observerValue nonretainedObjectValue];
        void(^updateBlock)(id observer, NSString* path) = [observersToUpdateBlocks objectForKey:observerValue];
        updateBlock(observer,mostRecentPath);
    }
}

- (void)resourcesDidUpdateWithExtensions:(NSSet*)extensions{
    for(NSString* extension in extensions){
        NSMutableDictionary* observersToUpdateBlocks = [self.updateExtensionsDictionary objectForKey:extension];
        
        NSArray* updatedFiles = [RMResourceManager pathsForResourcesWithExtension:extension];
        
        for(NSValue* observerValue in [observersToUpdateBlocks allKeys]){
            id observer = [observerValue nonretainedObjectValue];
            void(^updateBlock)(id observer, NSArray* paths) = [observersToUpdateBlocks objectForKey:observerValue];
            updateBlock(observer,updatedFiles);
        }
    }
}

@end
