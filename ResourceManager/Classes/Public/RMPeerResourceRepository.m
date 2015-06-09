//
//  RMPeerResourceRepository.m
//  ResourceManager
//
//  Created by Sebastien Morel on 2015-04-07.
//  Copyright (c) 2015 Sebastien Morel. All rights reserved.
//

#import "RMPeerResourceRepository.h"
#import "AppPeer.h"
#import <objc/runtime.h>

@interface UIAlertView(RMPeerResourceRepository)
@property(nonatomic,retain) APPeer* peer;
@end

@implementation UIAlertView(RMPeerResourceRepository)

static char UIAlertViewPeerKey;

- (void)setPeer:(APPeer *)peer{
    objc_setAssociatedObject(self, &UIAlertViewPeerKey, peer, OBJC_ASSOCIATION_RETAIN);
}

- (APPeer*)peer{
    return objc_getAssociatedObject(self, &UIAlertViewPeerKey);
}

@end



@interface RMPeerResourceRepository()
@property(nonatomic,retain) APHub* hub;
@end

@implementation RMPeerResourceRepository

- (void)connect{
    [self setupHub];
    
}

- (void)disconnect{
    [self.hub close];
    self.hub = nil;
}

- (NSString*)peerDescription{
    NSString* name = [UIDevice currentDevice].name;
    return [NSString stringWithFormat:@"1______%@",name];
}

- (NSString*)peerDomain{
    NSString* bundleIdentifier = [[[NSBundle mainBundle]bundleIdentifier]stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    return [NSString stringWithFormat:@"%@_%@",@"RMPeerResourceRepository",bundleIdentifier];
}

- (NSDictionary*)peerAttributes:(APPeer*)peer{
    NSString* desc = peer.name;//make sure it is a valid base 64!
    NSInteger role = [[desc substringToIndex:1]integerValue];
    NSString* name = [desc substringFromIndex:7];
    return @{ @"name" : name, @"role" : @(role) };
}

- (void)setupHub{
    __weak RMPeerResourceRepository* bself = self;
    
    self.hub = [[APHub alloc] initWithName:[self peerDescription] subdomain:[self peerDomain]];
    self.hub.autoConnect = NO;
    
    self.hub.didReceiveDataFromPeerBlock = ^(NSData *data, APPeer *peer) {
        NSError* error = nil;
        NSArray* array = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        [bself didReceiveUpdates:array];
    };
    
    self.hub.didFindPeerBlock = ^(APPeer *peer) {
        NSDictionary* attributes = [bself peerAttributes:peer];
        if([[attributes objectForKey:@"role"]integerValue] == 0){
            NSLog(@"ResourceManager: Did find peer %@",[attributes objectForKey:@"name"]);
            dispatch_async(dispatch_get_main_queue(), ^{
                [bself promptAlertForConnectingToPeer:peer];
            });
        }
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
    NSDictionary* attributes = [self peerAttributes:peer];
    
    NSString* message = [NSString stringWithFormat:@"Would you like to connect to resource server '%@'",[attributes objectForKey:@"name"]];
    UIAlertView* alertView = [[UIAlertView alloc]initWithTitle:@"Resource Manager" message:message delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
    alertView.peer = peer;
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex == 1){
        [self.hub connectToPeer:alertView.peer];
    }
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
