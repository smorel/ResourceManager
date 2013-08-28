//
//  RMDropboxPermissions.m
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-17.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import "RMDropboxPermissions.h"
#import "RMResourceManager.h"

@interface RMDropboxPermissions()
@property(nonatomic,assign) BOOL available;
@property(nonatomic,retain) DBAccountInfo* account;
@property(nonatomic,retain) NSMutableDictionary* allowedUsersByFolder;
@property(nonatomic,retain) NSMutableDictionary* allowedUsersByExtension;
@end

@implementation RMDropboxPermissions

- (id)initWithAccount:(DBAccountInfo*)theAccount{
    self = [super init];
    
    self.account = theAccount;
    
    NSString* filePath = [RMResourceManager pathForResource:@"ResourceManager" ofType:@"permissions"];
    [self loadPermissionFromPath:filePath];
    
    __unsafe_unretained RMDropboxPermissions* bself = self;
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
    if(!object || ![object isKindOfClass:[NSArray class]]){
        //TODO : Log error
        return;
    }
    
    for(NSDictionary* permission in object){
        NSArray* users = [permission objectForKey:@"users"];
        if(users && users.count > 0){
            NSString* folder = [permission objectForKey:@"folder"];
            if(folder){
                NSMutableArray* lowerCaseUsers = [NSMutableArray arrayWithCapacity:users.count];
                for(NSString* user in users){
                    [lowerCaseUsers addObject:[user lowercaseString]];
                }
                [self.allowedUsersByFolder setObject:lowerCaseUsers forKey:folder];
            }else{
                NSString* extension = [permission objectForKey:@"extension"];
                if(extension){
                    NSMutableArray* lowerCaseUsers = [NSMutableArray arrayWithCapacity:users.count];
                    for(NSString* user in users){
                        [lowerCaseUsers addObject:[user lowercaseString]];
                    }
                    [self.allowedUsersByExtension setObject:lowerCaseUsers forKey:folder];
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
    NSString* currentUser = [self.account.displayName lowercaseString];
    NSInteger index = [allowedUsers indexOfObject:currentUser];
    return index != NSNotFound;
}

- (BOOL)iterateOnDirectoryAccess:(NSString*)directory{
    if([directory hasPrefix:@"/"]){
        directory = [directory stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:@""];
    }
    if([directory hasSuffix:@"/"]){
        directory = [directory stringByReplacingCharactersInRange:NSMakeRange(directory.length-1,1) withString:@""];
    }
        
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
