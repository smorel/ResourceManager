//
//  RMWeakLinkedDBSession.m
//  ResourceManager
//
//  Created by Sebastien Morel on 3/17/2014.
//  Copyright (c) 2014 Sebastien Morel. All rights reserved.
//

#import "RMWeakLinkedDBSession.h"
#import "DropboxSDK.h"
#import <UIKit/UIKit.h>

@interface RMWeakLinkedDBSession()
@property (nonatomic, retain) id dbSession;
@end

static RMWeakLinkedDBSession* kSharedSession = nil;

@implementation RMWeakLinkedDBSession

- (id)initWithAppKey:(NSString *)key appSecret:(NSString *)secret{
    self = [super init];
    
    Class DBSessionClass = NSClassFromString(@"DBSession");
    if(!DBSessionClass)
        return self;
    
    self.dbSession = [[DBSessionClass alloc]initWithAppKey:key appSecret:secret root:@"dropbox"];
    
    return self;
}


+ (RMWeakLinkedDBSession*)sharedSession{
    return kSharedSession;
}

+ (void)setSharedSession:(RMWeakLinkedDBSession *)session{
    kSharedSession = session;
    
    
    Class DBSessionClass = NSClassFromString(@"DBSession");
    if(!DBSessionClass)
        return;
    
    [DBSessionClass setSharedSession:session.dbSession];
}

- (BOOL)isLinked{
    Class DBSessionClass = NSClassFromString(@"DBSession");
    if(!DBSessionClass)
        return NO;
    
    return [self.dbSession isLinked];
}

- (void)unlinkAll{
    Class DBSessionClass = NSClassFromString(@"DBSession");
    if(!DBSessionClass)
        return;
    [self.dbSession unlinkAll];
}

- (void)unlinkUserId:(NSString *)userId{
    Class DBSessionClass = NSClassFromString(@"DBSession");
    if(!DBSessionClass)
        return;
    [self.dbSession unlinkUserId:userId];
}

- (NSString*)root{
    Class DBSessionClass = NSClassFromString(@"DBSession");
    if(!DBSessionClass)
        return nil;
    
    return [self.dbSession root];
}

- (NSArray*)userIds{
    Class DBSessionClass = NSClassFromString(@"DBSession");
    if(!DBSessionClass)
        return nil;
    
    return [self.dbSession userIds];
}

- (id)delegate{
    Class DBSessionClass = NSClassFromString(@"DBSession");
    if(!DBSessionClass)
        return nil;
    
    return [self.dbSession delegate];
}

- (void)setDelegate:(id)delegate{
    Class DBSessionClass = NSClassFromString(@"DBSession");
    if(!DBSessionClass)
        return;
    
    [self.dbSession setDelegate:delegate];
}


- (void)linkFromController:(UIViewController *)rootController{
    Class DBSessionClass = NSClassFromString(@"DBSession");
    if(!DBSessionClass)
        return;
    
    [self.dbSession linkFromController:rootController];
}

- (BOOL)handleOpenURL:(NSURL *)url{
    Class DBSessionClass = NSClassFromString(@"DBSession");
    if(!DBSessionClass)
        return NO;
    
    return [self.dbSession handleOpenURL:url];
}

@end
