//
//  main.m
//  RMPeerDeamon
//
//  Created by Sebastien Morel on 2015-04-07.
//  Copyright (c) 2015 Sebastien Morel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMPeerDeamon.h"


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSMutableArray* directories = [NSMutableArray array];
        for(int i =1;i<argc;++i){
            [directories addObject:[NSString stringWithUTF8String:argv[i]]];
        }
        RMPeerDeamon* deamon = [[RMPeerDeamon alloc]initWithDirectories:directories];
        [deamon start];
        [[NSRunLoop currentRunLoop] run];
    }
    return 0;
}
