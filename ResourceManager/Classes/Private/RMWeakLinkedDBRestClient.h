//
//  RMWeakLinkedDBRestClient.h
//  ResourceManager
//
//  Created by Sebastien Morel on 3/17/2014.
//  Copyright (c) 2014 Sebastien Morel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "RMWeakLinkedDBSession.h"

@interface RMWeakLinkedDBRestClient : NSObject

- (id)initWithSession:(RMWeakLinkedDBSession*)session;
- (void)loadAccountInfo;
- (void)loadMetadata:(NSString*)path;
- (void)loadFile:(NSString *)path intoPath:(NSString *)destinationPath;

@property (nonatomic, assign) id delegate;

@end
