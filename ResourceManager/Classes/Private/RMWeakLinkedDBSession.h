//
//  RMWeakLinkedDBSession.h
//  ResourceManager
//
//  Created by Sebastien Morel on 3/17/2014.
//  Copyright (c) 2014 Sebastien Morel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface RMWeakLinkedDBSession : NSObject

- (id)initWithAppKey:(NSString *)key appSecret:(NSString *)secret;

+ (RMWeakLinkedDBSession*)sharedSession;
+ (void)setSharedSession:(RMWeakLinkedDBSession *)session;

- (BOOL)isLinked; // Session must be linked before creating any DBRestClient objects

- (void)unlinkAll;
- (void)unlinkUserId:(NSString *)userId;

@property (nonatomic, readonly) NSString *root;
@property (nonatomic, readonly) NSArray *userIds;
@property (nonatomic, assign) id delegate;

- (void)linkFromController:(UIViewController *)rootController;

- (BOOL)handleOpenURL:(NSURL *)url;

@end
