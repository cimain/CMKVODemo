//
//  NSObject+Delegate_KVO.h
//  CM_KeyValueObserveDemo
//

//  Created by ChenMan on 2018/4/19.
//  Copyright © 2018年 cimain. All rights reserved.
//


#import <Foundation/Foundation.h>

@protocol ObserverDelegate<NSObject>

@optional
/**
 回调
 
 @param keyPath 属性名称
 @param object 被观察的对象
 */
-(void)CM_ObserveValueForKeyPath:(NSString *)keyPath ofObject:(id)object oldValue:(id) oldValue newValue:(id)newValue;


@end

@interface NSObject (Delegate_KVO)<ObserverDelegate>

/**
 *  method stead of traditional addObserver API
 *
 *  @param object          object as observer
 *  @param key             attribute of object to be observed
 */
- (void)CM_addObserver: (NSObject *)object forKey: (NSString *)key;


/**
 *  remove the observe
 *
 *  @param object object as observer
 *  @param key    attribute observed will remove the observe
 */
- (void)CM_removeObserver: (NSObject *)object forKey: (NSString *)key;


@end
