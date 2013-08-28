//
//  RMBundleResourceRepository.m
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-19.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import "RMBundleResourceRepository.h"

@interface RMBundleResourceRepository()
@property(nonatomic, retain) NSBundle* bundle;
@end

@implementation RMBundleResourceRepository{
    dispatch_queue_t _processQueue;
}

- (id)initWithBundle:(NSBundle*)theBundle{
    self = [super init];
    self.bundle = theBundle;
    self.pullingTimeInterval = 3;
    return self;
}

- (id)initWithPath:(NSString*)path{
    NSBundle* bundleAtPath = [NSBundle bundleWithPath:path];
    return [self initWithBundle:bundleAtPath];
}

- (void)disconnect{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)connect{
    _processQueue = dispatch_queue_create("com.wherecloud.resourcemanager.bundlerepository", 0);
    [self pull];
}

+ (BOOL)shouldSkipFileWithUrl:(NSURL*)url{
    
    BOOL directory = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&directory];
    
    NSString* path = [url path];
    NSString* extension = [path pathExtension];
    if(   [extension isEqualToString:@"h"]
       || [extension isEqualToString:@"m"]
       || [extension isEqualToString:@"mm"]
       || [extension isEqualToString:@"pch"]
       || [extension isEqualToString:@"a"]
       || [extension isEqualToString:@"c"]
       || [extension isEqualToString:@"rb"]
       || [extension isEqualToString:@"framework"]
       || [extension isEqualToString:@"xcodeproj"]
       || [extension isEqualToString:@"git"]
       || (!directory && (extension == nil || [extension length] <= 0))
    ){
        return YES;
    }

    return NO;
}

+ (void)appendFilePathFromDirectory:(NSURL *)directoryUrl toArray:(NSMutableArray*)array usingFileManager:(NSFileManager*)fileManager{
    NSArray *urls = [fileManager
                      contentsOfDirectoryAtURL:directoryUrl
                      includingPropertiesForKeys:[NSArray arrayWithObject:NSURLContentModificationDateKey]
                      options:(NSDirectoryEnumerationSkipsHiddenFiles)
                      error:nil];
    
    for (NSURL *fileSystemItem in urls) {
        if([self shouldSkipFileWithUrl:fileSystemItem])
            continue;
        
        BOOL directory = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:[fileSystemItem path] isDirectory:&directory];
        if (!directory) {
            [array addObject:[fileSystemItem path]];
        }
        else {
            [RMBundleResourceRepository appendFilePathFromDirectory:fileSystemItem toArray:array usingFileManager:fileManager];
        }
    }
}

- (void)pull{
    dispatch_async(_processQueue, ^{
        @autoreleasepool {
            NSFileManager* fileManager = [[NSFileManager alloc]init];
            
            NSMutableArray* allFiles = [NSMutableArray array];
            [RMBundleResourceRepository appendFilePathFromDirectory:[self.bundle bundleURL]
                                                            toArray:allFiles
                                                   usingFileManager:fileManager];
            
            NSMutableArray* updates = [NSMutableArray array];
            
            for(NSString* path in allFiles){
                NSError* error = nil;
                
                NSDictionary* fileProperties = [fileManager attributesOfItemAtPath:path error:&error];
                NSDate* fileModifiedDate = [fileProperties objectForKey:NSFileModificationDate];
                
                NSString* relativePath = [self relativePathForResourceWithPath:path];
                BOOL shouldCopy = [self.delegate shouldRepository:self updateFileWithRelativePath:relativePath modificationDate:fileModifiedDate];
                if(shouldCopy){
                    NSString* destinationPath = [self.delegate repository:self requestStoragePathForFileWithRelativePath:relativePath];
                    if([fileManager fileExistsAtPath:destinationPath]){
                        [fileManager removeItemAtPath:destinationPath error:&error];
                    }
                    [fileManager copyItemAtPath:path toPath:destinationPath error:&error];
                    [updates addObject:destinationPath];
                }
            }
            
            if(updates.count > 0){
                [self.delegate repository:self didReceiveUpdates:updates revokedAccess:[NSArray array]];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self triggerNextPulling];
        });
    });
}

- (void)triggerNextPulling{
    [self performSelector:@selector(pull) withObject:nil afterDelay:self.pullingTimeInterval];
}

@end
