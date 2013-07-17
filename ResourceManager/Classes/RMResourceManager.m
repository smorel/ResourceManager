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
NSString* RMResourceManagerApplicationFullPathKey = @"RMResourceManagerApplicationFullPathKey";
NSString* RMResourceManagerRelativePathKey = @"RMResourceManagerRelativePathKey";
NSString* RMResourceManagerMostRecentPathKey = @"RMResourceManagerMostRecentPathKey";

static RMResourceManager* kSharedManager = nil;

@interface RMResourceManager()<DBSessionDelegate>

@property (nonatomic, retain) DBSession* dbSession;
@property (nonatomic, retain) NSString* localResourcesDirectory;
@property (nonatomic, retain) NSString* dropboxFolder;
@property (nonatomic, retain) RMFileSystem* fileSystem;

@end

@implementation RMResourceManager

+ (void)load{
    [self subClassComponents];
}

+ (void)setSharedManager:(RMResourceManager*)manager{
    kSharedManager = manager;
}

+ (RMResourceManager*)sharedManager{
    return kSharedManager;
}

- (id)initWithAppKey:(NSString*)appKey secret:(NSString*)secret dropboxFolder:(NSString*)folder localResourcesDirectory:(NSString*)theLocalResourcesDirectory{
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

    
    self.localResourcesDirectory = theLocalResourcesDirectory;
    
    return self;
}

- (id)initWithAppKey:(NSString*)appKey secret:(NSString*)secret dropboxFolder:(NSString*)folder {
    return [self initWithAppKey:appKey secret:secret dropboxFolder:folder localResourcesDirectory:nil];
}

- (id)initWithLocalResourcesDirectory:(NSString*)localResourcesDirectory{
    return [self initWithAppKey:nil secret:nil dropboxFolder:nil localResourcesDirectory:localResourcesDirectory];
}


- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId{
    [self presentsLinkAccountViewController];
}

- (void)handleApplication:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    if (![[DBSession sharedSession] isLinked]) {
        [self presentsLinkAccountViewController];
    }
}

- (void)handleApplication:(UIApplication *)application openURL:(NSURL *)url{
	if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            [self startResourceManagement];
        }
    }
}

- (void)presentsLinkAccountViewController{
    UIViewController* root = [[[[UIApplication sharedApplication]windows]objectAtIndex:0]rootViewController];
    NSAssert(root,@"Your application's main window has no root view controller.");
 
    [[DBSession sharedSession] linkFromController:root];
}

- (void)startResourceManagement{
    self.fileSystem = [[RMFileSystem alloc]initWithDropboxFolder:self.dropboxFolder];
    self.fileSystem.pullingTimeInterval = self.pullingTimeInterval;
}

- (void)setPullingTimeInterval:(NSTimeInterval)thePullingTimeInterval{
    _pullingTimeInterval = thePullingTimeInterval;
    if(self.fileSystem){
        self.fileSystem.pullingTimeInterval = self.pullingTimeInterval;
    }
}


- (NSString *)pathForResource:(NSString *)name ofType:(NSString *)ext{
    NSString* path = [[NSBundle mainBundle]pathForResource:name ofType:ext];
    if(!self.fileSystem)
        return path;
    
    if(path){
        return [self.fileSystem pathForResourceAtPath:path];
    }
    
    //Resource is not embedded in app. Check in the file system for dropbox resource.
    NSString* currentLocale = [[NSLocale preferredLanguages] objectAtIndex:0];
    path = [self.fileSystem pathForResource:name ofType:ext forLocalization:currentLocale];
    if(!path){
        path = [self.fileSystem pathForResource:name ofType:ext forLocalization:@"en"];
    }
    if(!path){
        path = [self.fileSystem pathForResource:name ofType:ext forLocalization:nil];
    }
    return path;
}

+ (void)subClassComponents{
    [UIImage initResourceManagement];
}

@end
