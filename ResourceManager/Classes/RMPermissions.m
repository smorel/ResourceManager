//
//  RMPermissions.m
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-17.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import "RMPermissions.h"
#import "RMResourceManager.h"
#import <DropboxSDK/DropboxSDK.h>

@interface RMPermissions()
@property(nonatomic,assign) BOOL available;
@property(nonatomic,retain) NSMutableDictionary* allowedUsersByFolder;
@property(nonatomic,retain) NSMutableDictionary* allowedUsersByExtension;
@end

@implementation RMPermissions

- (id)init{
    self = [super init];
    
    NSString* filePath = [RMResourceManager pathForResource:@"ResourceManager" ofType:@"permissions"];
    [self loadPermissionFromPath:filePath];
    
    __unsafe_unretained RMPermissions* bself = self;
    [RMResourceManager addObserverForResourcesWithExtension:@"permissions" object:self usingBlock:^(id observer, NSArray *paths) {
        for(NSString* path in paths){
            if([path hasSuffix:@"ResourceManager.permissions" ]){
                [bself loadPermissionFromPath:path];
            }
        }
    }];
    
    return self;
}

- (void)dealloc{
    [RMResourceManager removeObserver:self];
}

- (void)loadPermissionFromPath:(NSString*)path{
    if(!path){
        self.available = NO;
        return;
    }
    
    self.allowedUsersByFolder    = [NSMutableDictionary dictionary];
    self.allowedUsersByExtension = [NSMutableDictionary dictionary];
    
    NSData* data = [NSData dataWithContentsOfFile:path];
    
    NSError* error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    NSAssert([object isKindOfClass:[NSArray class]],@"invalid content for permissions");
    
    for(NSDictionary* permission in object){
        NSArray* users = [permission objectForKey:@"users"];
        if(users && users.count > 0){
            NSString* folder = [permission objectForKey:@"folder"];
            if(folder){
                [self.allowedUsersByFolder setObject:users forKey:folder];
            }else{
                NSString* extension = [permission objectForKey:@"extension"];
                if(extension){
                    [self.allowedUsersByExtension setObject:users forKey:folder];
                }
            }
        }
    }
    
    self.available = YES;
}

- (void)setAvailable:(BOOL)theAvailable{
    if(_available != theAvailable){
        _available = theAvailable;
        if(self.availabilityBlock){
            self.availabilityBlock(self.available);
        }
    }
}

- (BOOL)arePermissionsAvailable{
    return self.available;
}

- (BOOL)isSessionUserAllowed:(NSArray*)allowedUsers{
    NSArray* currentUsers = [[DBSession sharedSession]userIds];
    for(NSString* userId in currentUsers){
        NSInteger index = [allowedUsers indexOfObject:userId];
        if(index != NSNotFound)
            return YES;
    }
    
    return NO;
}

- (BOOL)iterateOnDirectoryAccess:(NSString*)directory{
    if(!directory || directory.length <= 0)
        return YES;
    
    NSArray* users = [self.allowedUsersByFolder objectForKey:directory];
    if(!users){
        NSString* nextDirectory = [directory stringByDeletingLastPathComponent];
        if([nextDirectory isEqualToString:directory])//root
            return YES;
        
        return [self iterateOnDirectoryAccess:nextDirectory];
    }
    
    return [self isSessionUserAllowed:users];
}

- (BOOL)canAccesFilesInDirectory:(NSString*)directory{
    return [self iterateOnDirectoryAccess:directory];
}

- (BOOL)canAccessFilesWithExtension:(NSString*)extension{
    NSArray* users = [self.allowedUsersByExtension objectForKey:extension];
    if(!users)
        return YES;
    
    return [self isSessionUserAllowed:users];
}

@end
