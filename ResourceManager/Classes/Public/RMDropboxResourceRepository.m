//
//  RMDropboxResourceRepository.m
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-19.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import "RMDropboxResourceRepository.h"
#import "DropboxSDK.h"
#import "RMDropboxPermissions.h"

typedef enum RMDropboxResourceRepositoryState{
    RMDropboxResourceRepositoryStateIdle,
    RMDropboxResourceRepositoryStateLoadingAccount,
    RMDropboxResourceRepositoryStatePulling,
    RMDropboxResourceRepositoryStateDownloading,
    RMDropboxResourceRepositoryStateNotifying
}RMDropboxResourceRepositoryState;

@interface RMDropboxResourceRepository()<DBSessionDelegate,DBRestClientDelegate>
@property (nonatomic, retain) DBSession* dbSession;
@property (nonatomic, retain) DBRestClient* dbClient;
@property (nonatomic, retain) NSString* rootDirectory;
@property (nonatomic, assign, readwrite) RMDropboxResourceRepositoryState state;

@property (nonatomic, retain) NSMutableArray* dropboxResourcesMetadata;
@property (nonatomic, assign) NSInteger metaDataRequestCount;

@property (nonatomic, retain) NSArray* pendingDowloads;
@property (nonatomic, assign) NSInteger pendingDownloadCount;

@property (nonatomic, retain) NSMutableSet* currentlyManagedFilePaths;
@property (nonatomic, retain) NSMutableSet* pendingManagedFilePaths;

@property (nonatomic, retain) RMDropboxPermissions* permissions;
@property (nonatomic, assign) BOOL stoppedDueToInvalidRootDirectory;

@end

@implementation RMDropboxResourceRepository{
    dispatch_queue_t _processQueue;
}

- (id)initWithAppKey:(NSString*)appKey secret:(NSString*)secret rootDirectory:(NSString*)directory{
    self = [super init];
    
    DBSession* dbSession = [[DBSession alloc] initWithAppKey:appKey appSecret:secret root:kDBRootDropbox];
    dbSession.delegate = self;
    [DBSession setSharedSession:dbSession];
    
    self.pullingTimeInterval = 3;
    self.rootDirectory = directory;
    self.currentlyManagedFilePaths = [NSMutableSet set];
    
    return self;
}

- (BOOL)isReady{
    return [[DBSession sharedSession] isLinked];
}

- (void)connect{
    if([self isReady]){
        [self start];
    }
}

- (void)disconnect{
    [self stop];
}

- (void)notifyThatRootDirectoryDoesntExistsOnDropboxAndStop{
    if(self.stoppedDueToInvalidRootDirectory)
        return;
    NSString* message = [NSString stringWithFormat:@"The folder '%@' does not exists in your account. Please create or correct this issue and relaunch your app to get the sync working properly.",self.rootDirectory];
    UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"DropBox Resource Repository Error" message:message
                                                  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    
    self.stoppedDueToInvalidRootDirectory = YES;
}

#pragma mark Authentification Management

- (void)handleApplication:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    if (![self isReady]) {
        NSLog(@"Starting Dropbox Authentification");
        [self presentsLinkAccountViewController];
    }
}

- (void)handleApplication:(UIApplication *)application openURL:(NSURL *)url{
    if(!url)
        return;
    
    if([[[url description]lowercaseString]hasSuffix:@"cancel"])
        return;
    
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        [self connect];
    }
}

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId{
    [[DBSession sharedSession]unlinkAll];
    [self presentsLinkAccountViewController];
}

- (void)presentsLinkAccountViewController{
    UIViewController* root = [[[[UIApplication sharedApplication]windows]objectAtIndex:0]rootViewController];
    NSAssert(root,@"Your application's main window has no root view controller.");
    [[DBSession sharedSession] linkFromController:root];
}

#pragma mark Synchronization status Management

- (void)start{
    NSLog(@"Starting Dropbox Synchronization");
    
    _processQueue = dispatch_queue_create("com.wherecloud.resourcemanager", 0);
    
    self.dbClient = [[DBRestClient alloc]initWithSession:[DBSession sharedSession]];
    self.dbClient.delegate = self;
    
    [self loadAccount];
}

- (void)stop{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)triggerNextPulling{
    self.state = RMDropboxResourceRepositoryStateIdle;
    
    if(self.stoppedDueToInvalidRootDirectory){
        [self disconnect];
        return;
    }
    
    [self performSelector:@selector(pull) withObject:nil afterDelay:self.pullingTimeInterval];
}

#pragma mark Account Management

- (void)loadAccount{
    self.state = RMDropboxResourceRepositoryStateLoadingAccount;
    [self.dbClient loadAccountInfo];
}

- (void)restClient:(DBRestClient*)client loadedAccountInfo:(DBAccountInfo*)info{
    self.permissions = [[RMDropboxPermissions alloc]initWithAccount:info];
    [self pull];
}

- (void)restClient:(DBRestClient*)client loadAccountInfoFailedWithError:(NSError*)error{
    if(error.code == NSURLErrorTimedOut){
        [self loadAccount];
    }   // [self pull];
}

#pragma mark Managing Permissions

- (NSString*)relativeDropboxFolderForPermissions:(NSString*)path{
    NSString * relativePath = [path stringByReplacingOccurrencesOfString:self.rootDirectory withString:@""];
    NSString * folder = [relativePath stringByDeletingLastPathComponent];
    return folder;
}

#pragma mark Processing dropbox resources

- (void)pull{
    self.state = RMDropboxResourceRepositoryStatePulling;
    
    self.dropboxResourcesMetadata = [NSMutableArray array];
    self.pendingManagedFilePaths = [NSMutableSet set];
    [self loadMetadata:self.rootDirectory];
}

- (void)loadMetadata:(NSString*)path{
    self.metaDataRequestCount++;
    [self.dbClient loadMetadata:path];
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    if (metadata.isDirectory && !metadata.isDeleted) {
        for (DBMetadata *file in metadata.contents) {
            if(file.isDirectory){
                [self loadMetadata:file.path];
            }else{
                NSString* fileName = [file.path lastPathComponent];
                if(![[fileName lowercaseString] isEqualToString:@"resourcemanager.permissions"]){
                    NSString* folder = [self relativeDropboxFolderForPermissions:file.path];
                    if(![self.permissions canAccesFilesInDirectory:folder]){
                        continue;
                    }
                    
                    NSString* extension = [file.path pathExtension];
                    if(![self.permissions canAccessFilesWithExtension:extension]){
                        continue;
                    }
                }
                
                NSString* relativePath = [self relativePathForResourceWithPath:file.path];
                [self.pendingManagedFilePaths addObject:relativePath];
                [self.dropboxResourcesMetadata addObject:file];
            }
        }
    }else if(metadata.isDeleted){
        [self restClient:client loadMetadataFailedWithError:[NSError errorWithDomain:@"RMDropboxResourceRepositoryDomain" code:-1 userInfo:@{@"metaData" : metadata}]];
        return;
    }
    
    self.metaDataRequestCount--;
    
    if(self.metaDataRequestCount == 0){
        [self processAndDownloadMostRecentResources];
    }
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
    self.metaDataRequestCount--;
    
    //Handle case where root folder has been deleted from dropbox
    if(error.code == -1 && [error.domain isEqualToString:@"RMDropboxResourceRepositoryDomain"]){
        DBMetadata* metaData = [error.userInfo objectForKey:@"metaData"];
        if(metaData.isDirectory && [metaData.path isEqualToString:self.rootDirectory]){
            [self notifyThatRootDirectoryDoesntExistsOnDropboxAndStop];
            return;
        }
    }
    
    //Handle the case where the root folder has never existed on dropbox
    if((error.code == 404 || error.code == DBErrorFileNotFound) && [error.domain isEqualToString:DBErrorDomain]){
        NSString* path = [error.userInfo objectForKey:@"path"];
        if([path isEqualToString:self.rootDirectory]){
            [self notifyThatRootDirectoryDoesntExistsOnDropboxAndStop];
            return;
        }
    }
    
    if(self.state != RMDropboxResourceRepositoryStateIdle){
        [self triggerNextPulling];
    }
}

- (void)processAndDownloadMostRecentResources{
    // dispatch_async(_processQueue, ^{
    NSMutableArray* filesToDownload = [NSMutableArray array];
    
    for(DBMetadata* file in self.dropboxResourcesMetadata){
        NSString* relativePath = [self relativePathForResourceWithPath:file.path];
        BOOL shouldDownload = [self.delegate shouldRepository:self updateFileWithRelativePath:relativePath modificationDate:file.lastModifiedDate];
        if(shouldDownload){
            [filesToDownload addObject:file];
        }
    }
    
    if(filesToDownload.count > 0){
        [self downloadFiles:filesToDownload];
    }else if(self.pendingManagedFilePaths.count != self.currentlyManagedFilePaths.count){
        [self notifyForUpdates];
    }else{
        [self triggerNextPulling];
    }
    //  });
}

#pragma mark Processing dropbox downloads

- (void)downloadFiles:(NSArray*)files{
    self.pendingDowloads = files;
    self.pendingDownloadCount = files.count;
    
    self.state = RMDropboxResourceRepositoryStateDownloading;
    
    for(DBMetadata* file in files){
        NSString* relativePath = [self relativePathForResourceWithPath:file.path];
        NSString* path = [self.delegate repository:self requestStoragePathForFileWithRelativePath:relativePath];
    
        if([[NSFileManager defaultManager]fileExistsAtPath:path]){
            NSError* error = nil;
            [[NSFileManager defaultManager]removeItemAtPath:path error:&error];
        }
        
        [self.dbClient loadFile:file.path intoPath:path];
    }
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath contentType:(NSString*)contentType metadata:(DBMetadata*)metadata {
    self.pendingDownloadCount--;
    
    if(self.pendingDownloadCount <= 0){
        [self notifyForUpdates];
    }
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error {
    self.pendingDownloadCount--;
    
    if(self.pendingDownloadCount <= 0){
        [self notifyForUpdates];
    }
}

#pragma mark Notifying update for download files or revoked files

- (void)notifyForUpdates{
    self.state = RMDropboxResourceRepositoryStateNotifying;
    
    //Manage files that have been updated
    NSMutableArray* updatedFilePaths = [NSMutableArray array];
    for(DBMetadata* file in self.pendingDowloads){
        NSString* relativePath = [self relativePathForResourceWithPath:file.path];
        NSString* path = [self.delegate repository:self requestStoragePathForFileWithRelativePath:relativePath];
        [updatedFilePaths addObject:path];
    }
    
    
    //Manage files that have been revoked or deleted
    NSMutableSet* revokedFilePaths = [NSMutableSet setWithSet:self.currentlyManagedFilePaths];
    [revokedFilePaths minusSet:self.pendingManagedFilePaths];
    
    NSMutableArray* revokedFiles = [NSMutableArray arrayWithCapacity:revokedFilePaths.count];
    
    if(revokedFilePaths.count > 0){
        for(NSString* relativePath in revokedFilePaths){
            NSString* path = [self.delegate repository:self requestStoragePathForFileWithRelativePath:relativePath];
            [revokedFiles addObject:path];
        }
    }
    
    //Notify delegate
    [self.delegate repository:self didReceiveUpdates:updatedFilePaths revokedAccess:revokedFiles];
    
    //Reset and trigger next pulling
    self.currentlyManagedFilePaths = self.pendingManagedFilePaths;
    self.pendingDowloads = nil;
    self.pendingManagedFilePaths = nil;
    
    [self triggerNextPulling];
}


#pragma mark HUD Management

- (void)setState:(RMDropboxResourceRepositoryState)theState{
    _state = theState;
    
    switch(_state){
        case RMDropboxResourceRepositoryStateIdle:{
            NSLog(@"IDLE...");
            [self notifyHudWitchMessage:nil];
            break;
        }
        case RMDropboxResourceRepositoryStateDownloading:
        {
            NSString* text = nil;
            if(self.pendingDowloads.count == 1){
                DBMetadata* meta = [self.pendingDowloads objectAtIndex:0];
                NSString* name = [[meta path]lastPathComponent];
                text = [NSString stringWithFormat:@"Downloading '%@'",name];
            }else{
                text = [NSString stringWithFormat:@"Downloading %lu files", (unsigned long)self.pendingDowloads.count];
            }
            [self notifyHudWitchMessage:text];
            break;
        }
        case RMDropboxResourceRepositoryStatePulling:
        {
            NSLog(@"Pulling...");
            [self notifyHudWitchMessage:nil];
            break;
        }
        case RMDropboxResourceRepositoryStateLoadingAccount:
        {
            [self notifyHudWitchMessage:@"Loading Account..."];
            break;
        }
        case RMDropboxResourceRepositoryStateNotifying:
        {
            [self notifyHudWitchMessage:@"Updating Application..."];
            break;
        }
    }
}

@end
