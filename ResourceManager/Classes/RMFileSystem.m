//
//  RMFileSystem.m
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-16.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import "RMFileSystem.h"
#import "RMResourceManager.h"

@interface RMFileSystem()<DBRestClientDelegate>

@property (nonatomic, retain) DBRestClient* dbClient;

@property (nonatomic, retain) NSMutableArray* dropboxResourcesMetadata;
@property (nonatomic, retain) NSString* rootFolder;
@property (nonatomic, assign) NSInteger metaDataRequestCount;

@property (nonatomic, retain) NSArray* pendingDowloads;
@property (nonatomic, assign) NSInteger pendingDownloadCount;

@end

@implementation RMFileSystem{
    dispatch_queue_t _processQueue;
}

- (id)initWithDropboxFolder:(NSString*)folder{
    self = [super init];
    
    self.dbClient = [[DBRestClient alloc]initWithSession:[DBSession sharedSession]];
    self.dbClient.delegate = self;
    self.rootFolder = folder ? folder : @"/";
    
    _processQueue = dispatch_queue_create("com.wherecloud.resourcemanager", 0);
    
    [self processDropBoxResources];
    
    return self;
}

- (void)processDropBoxResources{
    self.dropboxResourcesMetadata = [NSMutableArray array];
    [self loadMetadata:self.rootFolder];
}

- (void)loadMetadata:(NSString*)path{
    self.metaDataRequestCount++;
    [self.dbClient loadMetadata:path];
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    if (metadata.isDirectory) {
        for (DBMetadata *file in metadata.contents) {
            if(file.isDirectory){
                [self loadMetadata:file.path];
            }else{
                [self.dropboxResourcesMetadata addObject:file];
            }
        }
    }
    self.metaDataRequestCount--;
    
    if(self.metaDataRequestCount == 0){
        [self processAndDownloadMostRecentResources];
    }
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
    self.metaDataRequestCount--;
}

- (NSString*)cacheDirectory{
    static NSString* kCacheDirectory = nil;
    if(!kCacheDirectory){
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        basePath = [basePath stringByAppendingPathComponent:@"com.wherecloud.ResourceManager"];
        
        if(![[NSFileManager defaultManager]fileExistsAtPath:basePath]){
            NSError* error = nil;
            [[NSFileManager defaultManager]createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:&error];
        }
        
        kCacheDirectory = basePath;
    }
    return kCacheDirectory;
}

- (NSString*)cachePathForRelativeResourcePath:(NSString*)relativePath{
    NSString* path = [[self cacheDirectory]stringByAppendingPathComponent:relativePath];
    
    //Ensure sub directory has been created
    NSString* directory = [path stringByDeletingLastPathComponent];
    if(![[NSFileManager defaultManager]fileExistsAtPath:directory]){
        NSError* error = nil;
        [[NSFileManager defaultManager]createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    return path;
}

- (BOOL)needsToDownloadFile:(DBMetadata*)file{
    NSString* relativePath = [self relativePathFromDropboxPath:file.path];
    
    NSString* cachePath = [self cachePathForRelativeResourcePath:relativePath];
    if(![[NSFileManager defaultManager]fileExistsAtPath:cachePath]){
        return YES;
    }
    
    
    NSDate* dropBoxLastModifiedDate = file.lastModifiedDate;
    
    NSError* error = nil;
    NSDictionary* cacheFileProperties = [[NSFileManager defaultManager] attributesOfItemAtPath:cachePath error:&error];
    NSDate* cacheLastModifiedDate = [cacheFileProperties objectForKey:NSFileModificationDate];
    if([cacheLastModifiedDate compare: dropBoxLastModifiedDate] >= 1){
        return NO;
    }
    
    return YES;
}

- (NSString*)relativePathFromDropboxPath:(NSString*)dropboxPath{
    //TODO : Manages folders on dropbox and flatten hierarchy in cache directory
    //if no .lproj directory in dropboxPath, uses /filename.extension
    //else uses /language.lproj/filename.extension
    
    NSRange lprojRange = [dropboxPath rangeOfString:@"lproj"];
    if(lprojRange.location == NSNotFound){
        return [NSString stringWithFormat:@"/%@",[dropboxPath lastPathComponent]];
    }
    
    NSArray* pathComponents = [dropboxPath pathComponents];
    NSAssert(pathComponents.count >= 2,@"Localized file paths must at least have 2 path components");
    
    NSString* fileName = [pathComponents objectAtIndex:pathComponents.count - 1];
    NSString* localizationFolder = [pathComponents objectAtIndex:pathComponents.count - 2];
    
    return [NSString stringWithFormat:@"/%@/%@",localizationFolder,fileName];
}

- (void)processAndDownloadMostRecentResources{
   // dispatch_async(_processQueue, ^{
        NSMutableArray* filesToDownload = [NSMutableArray array];
        
    for(DBMetadata* file in self.dropboxResourcesMetadata){
            NSString* relativePath = [self relativePathFromDropboxPath:file.path];
            
            NSString* appPath = [[NSBundle mainBundle]pathForResource:relativePath ofType:nil];
            if(!appPath){
                if([self needsToDownloadFile:file]){
                    [filesToDownload addObject:file];
                    continue;
                }else{
                    //uses existing cache file
                    continue;
                }
            }
            
            NSError* error = nil;
            NSDictionary* appFileProperties = [[NSFileManager defaultManager] attributesOfItemAtPath:appPath error:&error];
            NSDate* appLastModifiedDate = [appFileProperties objectForKey:NSFileModificationDate];
            
            NSDate* dropBoxLastModifiedDate = file.lastModifiedDate;
            if([appLastModifiedDate compare: dropBoxLastModifiedDate] >= 1){
                //uses the app version
                continue;
            }
            
            if([self needsToDownloadFile:file]){
                [filesToDownload addObject:file];
                continue;
            }else{
                //uses existing cache file
                continue;
            }
        }
        
        if(filesToDownload.count > 0){
            [self downloadFiles:filesToDownload];
        }else{
            [self triggerNextPulling];
        }
  //  });
}

- (void)downloadFiles:(NSArray*)files{
    self.pendingDowloads = files;
    self.pendingDownloadCount = files.count;
    
    for(DBMetadata* file in files){
        NSString* relativePath = [self relativePathFromDropboxPath:file.path];
        
        NSString* cacheFilePath = [self cachePathForRelativeResourcePath:relativePath];
        if([[NSFileManager defaultManager]fileExistsAtPath:cacheFilePath]){
            NSError* error = nil;
            [[NSFileManager defaultManager]removeItemAtPath:cacheFilePath error:&error];
        }
        
        [self.dbClient loadFile:file.path intoPath:cacheFilePath];
    }
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath contentType:(NSString*)contentType metadata:(DBMetadata*)metadata {
    self.pendingDownloadCount--;
    
    if(self.pendingDownloadCount <= 0){
        [self notifyForUpdateAfterDownloads];
    }
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error {
    self.pendingDownloadCount--;
    
    if(self.pendingDownloadCount <= 0){
        [self notifyForUpdateAfterDownloads];
    }
}

- (void)notifyForUpdateAfterDownloads{
    NSMutableArray* files = [NSMutableArray arrayWithCapacity:self.pendingDowloads.count];
    
    for(DBMetadata* file in self.pendingDowloads){
        NSString* relativePath = [self relativePathFromDropboxPath:file.path];
        NSString* appPath = [[NSBundle mainBundle]pathForResource:relativePath ofType:nil];
        NSString* cachePath = [self cachePathForRelativeResourcePath:relativePath];
        
        NSDictionary* userData = @{
            RMResourceManagerApplicationBundlePathKey : appPath ? appPath : @"",
            RMResourceManagerRelativePathKey          : relativePath ? relativePath : @"",
            RMResourceManagerMostRecentPathKey        : cachePath ? cachePath : @""
        };
        [files addObject:userData];
        
        [[NSNotificationCenter defaultCenter]postNotificationName:RMResourceManagerFileDidUpdateNotification object:self userInfo:userData];
    }
    
    [[NSNotificationCenter defaultCenter]postNotificationName:RMResourceManagerDidEndUpdatingResourcesNotification object:self userInfo:@{RMResourceManagerUpdatedResourcesPathKey : files}];
    
    self.pendingDowloads = nil;
    
    [self triggerNextPulling];
}

- (void)triggerNextPulling{
    [self performSelector:@selector(processDropBoxResources) withObject:nil afterDelay:self.pullingTimeInterval];
}

- (NSString*)pathForResourceAtPath:(NSString*)applicationBundlePath{
    NSString* mainBundlePath = [[NSBundle mainBundle]bundlePath];
    NSString* relativePath = [applicationBundlePath stringByReplacingOccurrencesOfString:mainBundlePath withString:@""];
    
    NSString* cachePath = [self cachePathForRelativeResourcePath:relativePath];
    if(![[NSFileManager defaultManager]fileExistsAtPath:cachePath]){
        return applicationBundlePath;
    }
    
    NSError* error = nil;
    NSDictionary* appFileProperties = [[NSFileManager defaultManager] attributesOfItemAtPath:applicationBundlePath error:&error];
    NSDate* appLastModifiedDate = [appFileProperties objectForKey:NSFileModificationDate];
    
    NSDictionary* cacheFileProperties = [[NSFileManager defaultManager] attributesOfItemAtPath:cachePath error:&error];
    NSDate* cacheLastModifiedDate = [cacheFileProperties objectForKey:NSFileModificationDate];
    if([cacheLastModifiedDate compare: appLastModifiedDate] >= 1){
        return cachePath;
    }
    
    return applicationBundlePath;
}

- (NSString *)pathForResource:(NSString *)name ofType:(NSString *)ext forLocalization:(NSString *)localizationName{
    NSString* path = [self cacheDirectory];
    
    if(localizationName){
        path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.lproj",localizationName]];
    }
    
    path = [path stringByAppendingPathComponent:name];
    
    if(ext){
        path = [path stringByAppendingPathExtension:ext];
    }
    
    if([[NSFileManager defaultManager]fileExistsAtPath:path]){
        return path;
    }
    
    return nil;
}

- (NSString*) relativePathForPath:(NSString*)path{
    if(!path)
        return nil;
    
    NSString* mainBundlePath = [[NSBundle mainBundle]bundlePath];
    if([path hasPrefix:mainBundlePath]){
        return [path stringByReplacingOccurrencesOfString:mainBundlePath withString:@""];
    }
        
    NSString* cachePath = [self cacheDirectory];
    if([path hasPrefix:cachePath]){
        return [path stringByReplacingOccurrencesOfString:cachePath withString:@""];
    }
    return nil;
}


- (NSArray *)pathsForResourcesWithExtension:(NSString *)ext localization:(NSString *)localizationName{
    NSAssert(NO,@"Not implemented yet!");
    
    /*
    NSURL* cacheDirectoryUrl = [NSURL fileURLWithPath:[self cacheDirectory] isDirectory:YES];
    NSMutableArray *cachedFilesURLs = [[[NSFileManager defaultManager] contentsOfDirectoryAtURL:cacheDirectoryUrl
                                                                     includingPropertiesForKeys:[NSArray arrayWithObject:NSURLContentModificationDateKey]
                                                                                        options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                                          error:nil] mutableCopy];
    //Get the content of the localized folder
    //get the content of default language folder
    //merge localized and default folders by keeping the localized first
    
    //get the files with extension from the main bundle
    
    //merge by keeping the last updated file
    //return
     */
}

@end
