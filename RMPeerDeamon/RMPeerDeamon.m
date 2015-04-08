//
//  RMPeerDeamon.m
//  ResourceManager
//
//  Created by Sebastien Morel on 2015-04-07.
//  Copyright (c) 2015 Sebastien Morel. All rights reserved.
//

#import "RMPeerDeamon.h"
#import "RMPeerDeamonBundle.h"

#import <AppPeerMac/AppPeer.h>

@interface RMPeerDeamon()<RMPeerDeamonBundleDelegate>
@property(nonatomic,retain) RMPeerDeamonBundle* bundle;
@property(nonatomic,retain) APHub* hub;
@end

@implementation RMPeerDeamon

- (id)initWithDirectories:(NSArray*)directories{
    self = [super init];
    
    NSLog(@"Starting Deamon with directories: %@",directories);
    
    self.bundle = [[RMPeerDeamonBundle alloc]initWithDirectories:directories delegate:self];
    [self setupHub];
    return self;
}


- (void)setupHub{
    __weak RMPeerDeamon* bself = self;
    
    NSString* name = [NSHost currentHost].name;
    self.hub = [[APHub alloc] initWithName:name subdomain:@"RMPeerResourceRepository"];
    self.hub.autoConnect = NO;
    
    self.hub.didConnectToPeerBlock = ^(APPeer* peer){
        NSLog(@"ResourceManager: Did connect to peer %@",peer.name);
    };
    
    self.hub.didDisconnectFromPeerBlock = ^(APPeer *peer, NSError *error) {
        NSLog(@"ResourceManager: Did disconnect from peer %@",peer.name);
    };
    
    self.hub.didFindPeerBlock = ^(APPeer *peer) {
        NSLog(@"ResourceManager: Did find peer %@",peer.name);
    };
    
    self.hub.didReceiveDataFromPeerBlock = ^(NSData *data, APPeer *peer) {
        if(peer){
            dispatch_async(dispatch_get_main_queue(), ^{
                [bself.hub connectToPeer:peer];
            });
        }
    };
    
    [self.hub open];
}

- (void)start{
    [self pull];
    
}

- (void)pull{
    if(self.hub.connectedPeers.count > 0){
        NSLog(@"Pulling");
        
        [self.bundle pull];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self pull];
    });
}

- (NSData*)dataWithContentOfFiles:(NSArray*)filePaths{
    NSMutableArray* array = [NSMutableArray array];
    for(NSString* filePath in filePaths){
        NSLog(@"Send updates for file: %@",filePath);
        
        NSData* fileContent = [NSData dataWithContentsOfFile:filePath];
        NSString* base64 = [fileContent base64Encoding];
        [array addObject:@{ @"filepath" : filePath, @"content" : base64}];
    }
    
    NSError* error = nil;
    return [NSJSONSerialization dataWithJSONObject:array options:0 error:&error];
}

- (void)didCatchUpdateForFilesAtPath:(NSArray*)filePaths{
    NSData* data = [self dataWithContentOfFiles:filePaths];
    [self.hub broadcast:data];
}


@end
