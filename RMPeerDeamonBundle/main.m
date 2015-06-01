//
//  main.m
//  RMPeerDeamonBundle
//
//  Created by Sebastien Morel on 2015-04-08.
//  Copyright (c) 2015 Sebastien Morel. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RMPeerDeamon.h"


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSMutableArray* arguments = [NSMutableArray array];
        for(int i =1;i<argc;++i){
            NSString* arg = [NSString stringWithUTF8String:argv[i]];
            [arguments addObjectsFromArray:[arg componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        }
        
        NSMutableArray* directories = [NSMutableArray array];
        NSString* bundleIdentifier = nil;
        for(int i =0;i<arguments.count;++i){
            NSString* arg = arguments[i];
            if([arg isEqualToString:@"-directory"]){
                [directories addObject:arguments[i+1]];
                ++i;
            }else if ([arg isEqualToString:@"-bundle-identifier"]){
                bundleIdentifier = arguments[i+1];
                ++i;
            }
            
        }
        RMPeerDeamon* deamon = [[RMPeerDeamon alloc]initWithDirectories:directories bundleIdentifier:bundleIdentifier];
        [deamon start];
        [[NSRunLoop currentRunLoop] run];
    }
    return 0;
}
