//
//  RMRuntime.m
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-16.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import "RMRuntime.h"
#import <objc/runtime.h>

void RMSwizzleSelector(Class c,SEL selector, SEL newSelector){
	Method origMethod = class_getInstanceMethod(c, selector);
    Method newMethod  = class_getInstanceMethod(c, newSelector);
	
    method_exchangeImplementations(origMethod, newMethod);
}


void RMSwizzleClassSelector(Class c,SEL selector, SEL newSelector){
    Method origMethod = class_getClassMethod(c, selector);
    Method newMethod  = class_getClassMethod(c, newSelector);
	
    method_exchangeImplementations(origMethod, newMethod);
}