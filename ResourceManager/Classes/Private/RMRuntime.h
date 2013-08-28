//
//  RMRuntime.h
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-16.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#ifdef __cplusplus
extern "C" {
#endif
    
    /**
     */
    void RMSwizzleSelector(Class c,SEL selector, SEL newSelector);
    
    /**
     */
    void RMSwizzleClassSelector(Class c,SEL selector, SEL newSelector);
    
#ifdef __cplusplus
}
#endif