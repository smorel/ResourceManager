//
//  RMPeerDeamonBundle.m
//  ResourceManager
//
//  Created by Sebastien Morel on 2015-04-07.
//  Copyright (c) 2015 Sebastien Morel. All rights reserved.
//

#import "RMPeerDeamonBundle.h"

@interface RMPeerDeamonBundle()
@property(nonatomic, retain) id<RMPeerDeamonBundleDelegate> delegate;
@property(nonatomic, retain) NSMutableArray* bundles;
@property(nonatomic, retain) NSMutableDictionary* fileModifiedDates;
@end

@implementation RMPeerDeamonBundle

- (id)initWithDirectories:(NSArray*)directories delegate:(id<RMPeerDeamonBundleDelegate>)delegate{
    self = [super init];
    self.bundles = [NSMutableArray array];
    for(NSString* directory in directories){
        [self.bundles addObject: [[NSBundle alloc]initWithPath:directory]];
    }
    self.delegate = delegate;
    self.fileModifiedDates = [NSMutableDictionary dictionary];
    [self pullWithUpdate:NO];
    return self;
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
            [RMPeerDeamonBundle appendFilePathFromDirectory:fileSystemItem toArray:array usingFileManager:fileManager];
        }
    }
}

- (void)pull{
    [self pullWithUpdate:YES];
}

- (void)pullWithUpdate:(BOOL)withUpdates{
    NSFileManager* fileManager = [[NSFileManager alloc]init];
    
    NSMutableArray* allFiles = [NSMutableArray array];
    for(NSBundle* bundle in self.bundles){
        [RMPeerDeamonBundle appendFilePathFromDirectory:[bundle bundleURL]
                                                    toArray:allFiles
                                           usingFileManager:fileManager];
    }
    
    NSLog(@"Checking %lu files",(unsigned long)allFiles.count);
    
    NSMutableArray* updates = [NSMutableArray array];
    
    for(NSString* path in allFiles){
        NSError* error = nil;
        
        NSDictionary* fileProperties = [fileManager attributesOfItemAtPath:path error:&error];
        NSDate* fileModifiedDate = [fileProperties objectForKey:NSFileModificationDate];
        
        NSDate* modificationDate = [self.fileModifiedDates objectForKey:path];
        if(modificationDate){
            if([fileModifiedDate compare: modificationDate] > 0){
                if(withUpdates){
                    [updates addObject:path];
                }
            }
        }else{
            if(withUpdates){
                [updates addObject:path];
            }
        }
        
        [self.fileModifiedDates setObject:fileModifiedDate forKey:path];
    }
    
    if(updates.count > 0 && self.delegate){
        [self.delegate didCatchUpdateForFilesAtPath:updates];
    }
}

@end
