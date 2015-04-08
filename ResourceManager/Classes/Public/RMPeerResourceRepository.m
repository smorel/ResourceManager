//
//  RMPeerResourceRepository.m
//  ResourceManager
//
//  Created by Sebastien Morel on 2015-04-07.
//  Copyright (c) 2015 Sebastien Morel. All rights reserved.
//

#import "RMPeerResourceRepository.h"

#import <AppPeerIOS/AppPeer.h>

@interface RMPeerResourceRepository()
@property(nonatomic,retain) APHub* hub;
@property(nonatomic,retain) APPeer* pendingConnectionPeer;
@end

@implementation RMPeerResourceRepository

- (void)connect{
    [self setupHub];
    
}

- (void)disconnect{
    [self.hub close];
    self.hub = nil;
}

- (void)setupHub{
    __weak RMPeerResourceRepository* bself = self;
    
    
    NSString* name = [UIDevice currentDevice].name;
    NSString* bundleIdentifier = [[[NSBundle mainBundle]bundleIdentifier]stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    NSString* domain = [NSString stringWithFormat:@"%@_%@",@"RMPeerResourceRepository",bundleIdentifier];
    self.hub = [[APHub alloc] initWithName:name subdomain:domain];
    self.hub.autoConnect = NO;
    
    self.hub.didReceiveDataFromPeerBlock = ^(NSData *data, APPeer *peer) {
        NSError* error = nil;
        NSArray* array = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        [bself didReceiveUpdates:array];
    };
    
    self.hub.didFindPeerBlock = ^(APPeer *peer) {
        NSLog(@"ResourceManager: Did find peer %@",peer.name);
        bself.pendingConnectionPeer = peer;
        dispatch_async(dispatch_get_main_queue(), ^{
            [bself promptAlertForConnectingToPeer:peer];
        });
    };
    
    self.hub.didConnectToPeerBlock = ^(APPeer* peer){
        NSLog(@"ResourceManager: Did connect to peer %@",peer.name);
        [bself.hub send:[@"HEY" dataUsingEncoding:NSUTF8StringEncoding] toPeer:peer];
    };
    
    self.hub.didDisconnectFromPeerBlock = ^(APPeer *peer, NSError *error) {
        NSLog(@"ResourceManager: Did disconnect from peer %@",peer.name);
    };
    
    [self.hub open];
}

- (void)promptAlertForConnectingToPeer:(APPeer*)peer{
    NSString* message = [NSString stringWithFormat:@"Would you like to connect and receive updates from peer '%@'",peer.name];
    UIAlertView* alertView = [[UIAlertView alloc]initWithTitle:@"Resource Manager" message:message delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex == 1){
        [self.hub connectToPeer:self.pendingConnectionPeer];
    }
    self.pendingConnectionPeer = nil;
}

- (void)didReceiveUpdates:(NSArray*)changedFiles{
    NSMutableArray* updates = [NSMutableArray array];
    
    NSError* error = nil;
    for(NSDictionary* dico in changedFiles){
        NSString* filepath = [dico objectForKey:@"filepath"];
        NSString* base64 = [dico objectForKey:@"content"];
        NSData* content = [[NSData alloc]initWithBase64Encoding:base64];
    
        NSString* relativePath = [self relativePathForResourceWithPath:filepath];
        NSString* destinationPath = [self.delegate repository:self requestStoragePathForFileWithRelativePath:relativePath];
        
        NSFileManager* fileManager = [[NSFileManager alloc]init];
        if([fileManager fileExistsAtPath:destinationPath]){
            [fileManager removeItemAtPath:destinationPath error:&error];
        }
        [content writeToFile:destinationPath atomically:YES];
        
        [updates addObject:destinationPath];
    }

    if(updates.count > 0){
        [self.delegate repository:self didReceiveUpdates:updates revokedAccess:[NSArray array]];
    }

}


@end
