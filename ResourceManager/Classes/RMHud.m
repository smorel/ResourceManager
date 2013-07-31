//
//  RMHud.m
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-17.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import "RMHud.h"
#import "RMResourceRepository.h"


@interface RMHud()
@property (nonatomic, retain) UIView* view;
@property (nonatomic, retain) UILabel* infoLabel;
@property (nonatomic, retain) NSString* userTitle;
@end

@implementation RMHud

- (void)createView{
    self.view = [[UIView alloc]initWithFrame:CGRectMake(0,0,10,10)];
    self.infoLabel = [[UILabel alloc]initWithFrame:self.view.frame];
    self.infoLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.infoLabel];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.infoLabel.backgroundColor = [UIColor blackColor];
    self.infoLabel.textColor = [UIColor whiteColor];
    self.infoLabel.textAlignment = NSTextAlignmentCenter;
}

- (void)updateTitle:(NSString*)title{
    
    if(!self.view){
        [self createView];
    }
    
    
    if(title){
#ifdef DEBUG
        NSLog(@"%@",title);
#endif
    }
    
    NSArray* windows = [[UIApplication sharedApplication]windows];
    if([windows count] <= 0)
        return;
    
    UIViewController* root = [[windows objectAtIndex:0]rootViewController];
    if(!root){
        NSLog(@"RMHud needs your windows to get a rootViewController setup to be displayed!");
        return;
    }
    
    UIView* parentView = root.view;
    
    self.infoLabel.text = title;
    
    self.view.hidden = (self.infoLabel.text == nil);
    [self.infoLabel sizeToFit];
    self.view.frame = CGRectMake((parentView.bounds.size.width / 2) - ((self.infoLabel.bounds.size.width + 20) / 2),
                                 0, self.infoLabel.bounds.size.width + 20, self.infoLabel.bounds.size.height + 20);
    self.infoLabel.frame = self.view.bounds;
    
    [parentView addSubview:self.view];
    [parentView bringSubviewToFront:self.view];
    
}

- (void)setTitle:(NSString*)title{
    self.userTitle = title;
    [self updateTitle:title];
}

- (void)setTitleFromFileSystemUpdate:(NSString*)title{
    if(self.userTitle != nil)
        return;
    
    [self updateTitle:title];
}

- (void)repository:(RMResourceRepository*)repository didNotifyHudWithMessage:(NSString*)message{
    [self setTitleFromFileSystemUpdate:message];
}

- (void)disappear{
    [self.view removeFromSuperview];
}

@end
