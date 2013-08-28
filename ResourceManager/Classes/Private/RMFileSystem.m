//
//  RMFileSystem.m
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-16.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import "RMFileSystem.h"
#import "RMResourceManager.h"


NSString* RMResourceManagerFileDidUpdateNotification = @"RMResourceManagerFileDidUpdateNotification";
NSString* RMResourceManagerApplicationBundlePathKey  = @"RMResourceManagerApplicationBundlePathKey";
NSString* RMResourceManagerRelativePathKey           = @"RMResourceManagerRelativePathKey";
NSString* RMResourceManagerMostRecentPathKey         = @"RMResourceManagerMostRecentPathKey";

NSString* RMResourceManagerDidEndUpdatingResourcesNotification = @"RMResourceManagerDidEndUpdatingResourcesNotification";
NSString* RMResourceManagerUpdatedResourcesPathKey             = @"RMResourceManagerUpdatedResourcesPathKey";


@interface RMFileSystem()<RMResourceRepositoryDelegate>
@property(nonatomic, retain, readwrite) NSSet* repositories;
@property(nonatomic, retain) NSBundle* cacheBundle;
@end

@implementation RMFileSystem

- (id)initWithRepositories:(NSSet*)theRepositories{
    self = [super init];
    
    [self initializeCacheBundle];
    
    self.repositories = theRepositories;
    for(RMResourceRepository* repository in theRepositories){
        repository.delegate = self;
    }
    
    return self;
}

- (void)dealloc{
    for(RMResourceRepository* repository in self.repositories){
        repository.delegate = nil;
    }
}

#pragma mark Initializing cache

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

- (void)initializeCacheBundle{
    NSString* directory = [self cacheDirectory];
    self.cacheBundle = [[NSBundle alloc]initWithPath:directory];
}

#pragma mark Managing repositories

- (void)repository:(RMResourceRepository*)repository didReceiveUpdates:(NSArray*)filePaths revokedAccess:(NSArray*)revokedFilePaths{
    
    NSMutableArray* files = [NSMutableArray array];
    
    for(NSString* path in filePaths){
        NSString* relativePath = [RMFileSystem relativePathForResourceWithPath:path];
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
    
    for(NSString* path in revokedFilePaths){
        NSString* relativePath = [RMFileSystem relativePathForResourceWithPath:path];
        NSString* cachePath = [self cachePathForRelativeResourcePath:relativePath];
        
        if([[NSFileManager defaultManager]fileExistsAtPath:cachePath]){
            NSString* appPath = [[NSBundle mainBundle]pathForResource:relativePath ofType:nil];
            
            NSError* error = nil;
            [[NSFileManager defaultManager]removeItemAtPath:cachePath error:&error];
            
            NSDictionary* userData = @{
                    RMResourceManagerApplicationBundlePathKey : appPath ? appPath : @"",
                    RMResourceManagerRelativePathKey          : relativePath ? relativePath : @"",
                    RMResourceManagerMostRecentPathKey        : appPath ? appPath : @""
            };
            [files addObject:userData];
            
            [[NSNotificationCenter defaultCenter]postNotificationName:RMResourceManagerFileDidUpdateNotification object:self userInfo:userData];
        }
    }
    
    if(files.count > 0){
        [[NSNotificationCenter defaultCenter]postNotificationName:RMResourceManagerDidEndUpdatingResourcesNotification object:self userInfo:@{RMResourceManagerUpdatedResourcesPathKey : files}];
    }
    
}

- (BOOL)hasFileAtPath:(NSString*)path beenModifiedAfterDate:(NSDate*)modificationDate{
    NSError* error = nil;
    
    NSDictionary* fileProperties = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
    NSDate* fileModifiedDate = [fileProperties objectForKey:NSFileModificationDate];
    
    return [fileModifiedDate compare: modificationDate] >= 0;
}

- (BOOL)shouldRepository:(RMResourceRepository*)repository updateFileWithRelativePath:(NSString*)filePath modificationDate:(NSDate*)modificationDate{
    NSString* cachePath = [self cachePathForRelativeResourcePath:filePath];
    if(cachePath && [[NSFileManager defaultManager]fileExistsAtPath:cachePath]){
        return ![self hasFileAtPath:cachePath beenModifiedAfterDate:modificationDate];
    }
    
    NSString* appPath = [[NSBundle mainBundle]pathForResource:filePath ofType:nil];
    if(!appPath){
        return YES;
    }

    return ![self hasFileAtPath:appPath beenModifiedAfterDate:modificationDate];
}

- (NSString*)repository:(RMResourceRepository*)repository requestStoragePathForFileWithRelativePath:(NSString*)filePath{
    NSString* path = [self cachePathForRelativeResourcePath:filePath];
    NSString* directory = [path stringByDeletingLastPathComponent];
    
    if(![[NSFileManager defaultManager]fileExistsAtPath:directory]){
        [[NSFileManager defaultManager]createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return path;
}

- (void)repository:(RMResourceRepository*)repository didNotifyHudWithMessage:(NSString*)message{
    RMResourceManager* manager = [RMResourceManager performSelector:@selector(sharedManager)];
    if(manager){
        [manager performSelector:@selector(repository:didNotifyHudWithMessage:) withObject:repository withObject:message];
    }
}

#pragma mark Managing Resources

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

+ (NSString*)relativePathForResourceWithPath:(NSString*)path{
    NSRange lprojRange = [path rangeOfString:@"lproj"];
    if(lprojRange.location == NSNotFound){
        return [NSString stringWithFormat:@"/%@",[path lastPathComponent]];
    }
    
    NSArray* pathComponents = [path pathComponents];
    NSAssert(pathComponents.count >= 2,@"Localized file paths must at least have 2 path components");
    
    NSString* fileName = [pathComponents objectAtIndex:pathComponents.count - 1];
    NSString* localizationFolder = [pathComponents objectAtIndex:pathComponents.count - 2];
    
    return [NSString stringWithFormat:@"/%@/%@",localizationFolder,fileName];
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
    //TODO : see if we can use self.cacheBundle instead
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

- (NSArray*)filesInCacheWithExtension:(NSString*)extension localization:(NSString*)localizationName{
    NSArray* paths = [self.cacheBundle pathsForResourcesOfType:extension inDirectory:nil forLocalization:localizationName];
    return paths;
}

- (NSArray*)filesInApplicationBundleWithExtension:(NSString*)extension localization:(NSString*)localizationName{
    return [[NSBundle mainBundle]pathsForResourcesOfType:extension inDirectory:nil forLocalization:localizationName];
}

- (NSArray*)mergePathsFromCache:(NSArray*)cachePaths withApplicationBundlePaths:(NSArray*)appPaths{
    NSString* mainBundlePath = [[NSBundle mainBundle]bundlePath];
    
    NSMutableArray* noInAppCachePaths = [NSMutableArray arrayWithArray:cachePaths];
    
    //get the newest between app and cache
    NSMutableArray* finalPaths = [NSMutableArray array];
    for(NSString* appPath in appPaths){
        NSString* relativePath = [appPath stringByReplacingOccurrencesOfString:mainBundlePath withString:@""];
        NSString* cachePath = [self cachePathForRelativeResourcePath:relativePath];
        NSInteger index = [noInAppCachePaths indexOfObject:cachePath];
        
        if(index == NSNotFound){
            [finalPaths addObject:appPath];
            continue;
        }
        
        [noInAppCachePaths removeObjectAtIndex:index];
        
        NSError* error = nil;
        NSDictionary* appFileProperties = [[NSFileManager defaultManager] attributesOfItemAtPath:appPath error:&error];
        NSDate* appLastModifiedDate = [appFileProperties objectForKey:NSFileModificationDate];
        
        NSDictionary* cacheFileProperties = [[NSFileManager defaultManager] attributesOfItemAtPath:cachePath error:&error];
        NSDate* cacheLastModifiedDate = [cacheFileProperties objectForKey:NSFileModificationDate];
        if([cacheLastModifiedDate compare: appLastModifiedDate] >= 1){
            [finalPaths addObject:cachePath];
            continue;
        }
        
        [finalPaths addObject:appPath];
    }
    
    //get those in cache that are not in app
    for(NSString* cachePath in noInAppCachePaths){
        [finalPaths addObject:cachePath];
    }
    
    return finalPaths;
}

- (NSArray *)pathsForResourcesWithExtension:(NSString *)ext localization:(NSString *)localizationName{
    NSArray* cache = [self filesInCacheWithExtension:ext localization:localizationName];
    NSArray* app   = [self filesInApplicationBundleWithExtension:ext localization:localizationName];
    
    return [self mergePathsFromCache:cache withApplicationBundlePaths:app];
}
 

@end
