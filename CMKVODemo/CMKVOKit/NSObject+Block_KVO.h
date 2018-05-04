//
//  NSObject+Block_KVO.h
//  CMKVODemo
//
//  Created by ChenMan on 2018/5/4.
//  Copyright © 2018年 cimain. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CM_ObservingHandler) (id observedObject, NSString * observedKey, id oldValue, id newValue);

@interface NSObject (Block_KVO)

/**
 *  method stead of traditional addObserver API
 *
 *  @param object          object as observer
 *  @param key             attribute of object to be observed
 *  @param observedHandler method to be invoked when notification be observed has changed
 */
- (void)CM_addObserver: (NSObject *)object forKey: (NSString *)key withBlock: (CM_ObservingHandler)observedHandler;


/**
 *  remove the observe
 *
 *  @param object object as observer
 *  @param key    attribute observed will remove the observe
 */
- (void)CM_removeObserver: (NSObject *)object forKey: (NSString *)key;

@end
