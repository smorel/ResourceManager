//
//  RMWeakLinkedDBRestClient.m
//  ResourceManager
//
//  Created by Sebastien Morel on 3/17/2014.
//  Copyright (c) 2014 Sebastien Morel. All rights reserved.
//

#import "RMWeakLinkedDBRestClient.h"
#import "DropboxSDK.h"


@interface RMWeakLinkedDBSession()
@property (nonatomic, retain) id dbSession;
@end

@interface RMWeakLinkedDBRestClient()
@property (nonatomic, retain) id dbClient;
@end

@implementation RMWeakLinkedDBRestClient

- (id)initWithSession:(RMWeakLinkedDBSession*)session{
    self = [super init];
    
    Class DBRestClientClass = NSClassFromString(@"DBRestClient");
    if(DBRestClientClass){
        self.dbClient = [[DBRestClientClass alloc]initWithSession:session.dbSession];
    }
    
    return self;
}

- (id)delegate{
    Class DBRestClientClass = NSClassFromString(@"DBRestClient");
    if(!DBRestClientClass)
        return nil;
    
    return [self.dbClient delegate];
}

- (void)setDelegate:(id)delegate{
    Class DBRestClientClass = NSClassFromString(@"DBRestClient");
    if(!DBRestClientClass)
        return;
    
    [self.dbClient setDelegate:delegate];
}

- (void)loadAccountInfo{
    Class DBRestClientClass = NSClassFromString(@"DBRestClient");
    if(!DBRestClientClass)
        return;
    
    [self.dbClient loadAccountInfo];
}

- (void)loadMetadata:(NSString*)path{
    Class DBRestClientClass = NSClassFromString(@"DBRestClient");
    if(!DBRestClientClass)
        return;
    
    [self.dbClient loadMetadata:path];
}

- (void)loadFile:(NSString *)path intoPath:(NSString *)destinationPath{
    Class DBRestClientClass = NSClassFromString(@"DBRestClient");
    if(!DBRestClientClass)
        return;
    
    [self.dbClient loadFile:path intoPath:destinationPath];
}

@end
