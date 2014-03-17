//
//  RWWeakLinkedDBAccountInfo.m
//  ResourceManager
//
//  Created by Sebastien Morel on 3/17/2014.
//  Copyright (c) 2014 Sebastien Morel. All rights reserved.
//

#import "RWWeakLinkedDBAccountInfo.h"

@interface RWWeakLinkedDBAccountInfo()
@property(nonatomic,retain) id accountInfo;
@end

@implementation RWWeakLinkedDBAccountInfo

- (id)initWithAccountInfo:(id)accountInfo{
    self = [super init];
    self.accountInfo = accountInfo;
    return self;
}

- (NSString*)displayName{
    Class DBAccountInfoClass = NSClassFromString(@"DBAccountInfo");
    if(!DBAccountInfoClass)
        return NO;
    
    return [self.accountInfo displayName];
}

@end
