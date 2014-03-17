//
//  RMWeakLinkedDBMetadata.m
//  ResourceManager
//
//  Created by Sebastien Morel on 3/17/2014.
//  Copyright (c) 2014 Sebastien Morel. All rights reserved.
//

#import "RMWeakLinkedDBMetadata.h"
#import "DropboxSDK.h"

@interface RMWeakLinkedDBMetadata()
@property(nonatomic,retain) id metaData;
@end

@implementation RMWeakLinkedDBMetadata

- (id)initWithMetaData:(id)metaData{
    self = [super init];
    self.metaData = metaData;
    return self;
}

- (BOOL)isDirectory{
    Class DBMetadataClass = NSClassFromString(@"DBMetadata");
    if(!DBMetadataClass)
        return NO;
    
    return [self.metaData isDirectory];
}

- (BOOL)isDeleted{
    Class DBMetadataClass = NSClassFromString(@"DBMetadata");
    if(!DBMetadataClass)
        return NO;
    
    return [self.metaData isDeleted];
}

- (NSArray*)contents{
    Class DBMetadataClass = NSClassFromString(@"DBMetadata");
    if(!DBMetadataClass)
        return nil;
    
    return [self.metaData contents];
}

- (NSString*)path{
    Class DBMetadataClass = NSClassFromString(@"DBMetadata");
    if(!DBMetadataClass)
        return nil;
    
    return [self.metaData path];
}

- (NSDate*)lastModifiedDate{
    Class DBMetadataClass = NSClassFromString(@"DBMetadata");
    if(!DBMetadataClass)
        return nil;
    
    return [self.metaData lastModifiedDate];
}


@end
