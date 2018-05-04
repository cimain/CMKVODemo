//
//  NSObject+Block_KVO.m
//  CMKVODemo
//
//  Created by ChenMan on 2018/5/4.
//  Copyright © 2018年 cimain. All rights reserved.
//

#import "NSObject+Block_KVO.h"
#import <objc/runtime.h>
#import <objc/message.h>

//as prefix string of kvo class
static NSString * const kCMkvoClassPrefix_for_Block = @"CMObserver_";
static NSString * const kCMkvoAssiociateObserver_for_Block = @"CMAssiociateObserver";

@interface CMCM_ObserverInfo_for_Block : NSObject

@property (nonatomic, weak) NSObject * observer;
@property (nonatomic, copy) NSString * key;
@property (nonatomic, copy) CM_ObservingHandler handler;

@end


@implementation CMCM_ObserverInfo_for_Block

- (instancetype)initWithObserver: (NSObject *)observer forKey: (NSString *)key observeHandler: (CM_ObservingHandler)handler
{
    if (self = [super init]) {
        
        _observer = observer;
        self.key = key;
        self.handler = handler;
    }
    return self;
}

@end


#pragma mark -- Transform setter or getter to each other Methods
static NSString * setterForGetter(NSString * getter)
{
    if (getter.length <= 0) { return nil; }
    NSString * firstString = [[getter substringToIndex: 1] uppercaseString];
    NSString * leaveString = [getter substringFromIndex: 1];
    
    return [NSString stringWithFormat: @"set%@%@:", firstString, leaveString];
}


static NSString * getterForSetter(NSString * setter)
{
    if (setter.length <= 0 || ![setter hasPrefix: @"set"] || ![setter hasSuffix: @":"]) {
        
        return nil;
    }
    
    NSRange range = NSMakeRange(3, setter.length - 4);
    NSString * getter = [setter substringWithRange: range];
    
    NSString * firstString = [[getter substringToIndex: 1] lowercaseString];
    getter = [getter stringByReplacingCharactersInRange: NSMakeRange(0, 1) withString: firstString];
    
    return getter;
}


#pragma mark -- Override setter and getter Methods
static void KVO_setter(id self, SEL _cmd, id newValue)
{
    NSString * setterName = NSStringFromSelector(_cmd);
    NSString * getterName = getterForSetter(setterName);
    if (!getterName) {
        @throw [NSException exceptionWithName: NSInvalidArgumentException reason: [NSString stringWithFormat: @"unrecognized selector sent to instance %p", self] userInfo: nil];
        return;
    }
    
    id oldValue = [self valueForKey: getterName];
    struct objc_super superClass = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    
    [self willChangeValueForKey: getterName];
    void (*objc_msgSendSuperKVO)(void *, SEL, id) = (void *)objc_msgSendSuper;
    objc_msgSendSuperKVO(&superClass, _cmd, newValue);
    [self didChangeValueForKey: getterName];
    
    //获取所有监听回调对象进行回调
    NSMutableArray * observers = objc_getAssociatedObject(self, (__bridge const void *)kCMkvoAssiociateObserver_for_Block);
    for (CMCM_ObserverInfo_for_Block * info in observers) {
        if ([info.key isEqualToString: getterName]) {
            dispatch_async(dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                info.handler(self, getterName, oldValue, newValue);
            });
        }
    }
}


static Class kvo_Class(id self)
{
    return class_getSuperclass(object_getClass(self));
}



#pragma mark -- NSObject Category(KVO Reconstruct)
@implementation NSObject (Block_KVO)

- (void)CM_addObserver:(NSObject *)observer forKey:(NSString *)key withBlock:(CM_ObservingHandler)observedHandler
{
    //step 1 get setter method, if not, throw exception
    SEL setterSelector = NSSelectorFromString(setterForGetter(key));
    Method setterMethod = class_getInstanceMethod([self class], setterSelector);
    if (!setterMethod) {
        @throw [NSException exceptionWithName: NSInvalidArgumentException reason: [NSString stringWithFormat: @"unrecognized selector sent to instance %@", self] userInfo: nil];
        return;
    }
    Class observedClass = object_getClass(self);
    NSString * className = NSStringFromClass(observedClass);
    
    //如果被监听者没有CMObserver_，那么判断是否需要创建新类
    if (![className hasPrefix: kCMkvoClassPrefix_for_Block]) {
        observedClass = [self createKVOClassWithOriginalClassName: className];
        object_setClass(self, observedClass);
    }
    
    
    //add kvo setter method if its class(or superclass)hasn't implement setter
    if (![self hasSelector: setterSelector]) {
        const char * types = method_getTypeEncoding(setterMethod);
        class_addMethod(observedClass, setterSelector, (IMP)KVO_setter, types);
    }
    
    
    //add this observation info to saved new observer
    CMCM_ObserverInfo_for_Block * newInfo = [[CMCM_ObserverInfo_for_Block alloc] initWithObserver: observer forKey: key observeHandler: observedHandler];
    NSMutableArray * observers = objc_getAssociatedObject(self, (__bridge void *)kCMkvoAssiociateObserver_for_Block);
    
    if (!observers) {
        observers = [NSMutableArray array];
        objc_setAssociatedObject(self, (__bridge void *)kCMkvoAssiociateObserver_for_Block, observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [observers addObject: newInfo];
}


- (void)CM_removeObserver:(NSObject *)object forKey:(NSString *)key
{
    NSMutableArray * observers = objc_getAssociatedObject(self, (__bridge void *)kCMkvoAssiociateObserver_for_Block);
    
    CMCM_ObserverInfo_for_Block * observerRemoved = nil;
    for (CMCM_ObserverInfo_for_Block * observerInfo in observers) {
        
        if (observerInfo.observer == object && [observerInfo.key isEqualToString: key]) {
            
            observerRemoved = observerInfo;
            break;
        }
    }
    [observers removeObject: observerRemoved];
}


- (Class)createKVOClassWithOriginalClassName: (NSString *)className
{
    NSString * kvoClassName = [kCMkvoClassPrefix_for_Block stringByAppendingString: className];
    Class observedClass = NSClassFromString(kvoClassName);
    
    if (observedClass) { return observedClass; }
    
    //创建新类，并且添加CMObserver_为类名新前缀
    Class originalClass = object_getClass(self);
    Class kvoClass = objc_allocateClassPair(originalClass, kvoClassName.UTF8String, 0);
    
    //获取监听对象的class方法实现代码，然后替换新建类的class实现
    Method classMethod = class_getInstanceMethod(originalClass, @selector(class));
    const char * types = method_getTypeEncoding(classMethod);
    class_addMethod(kvoClass, @selector(class), (IMP)kvo_Class, types);
    objc_registerClassPair(kvoClass);
    return kvoClass;
}


- (BOOL)hasSelector: (SEL)selector
{
    Class observedClass = object_getClass(self);
    unsigned int methodCount = 0;
    Method * methodList = class_copyMethodList(observedClass, &methodCount);
    for (int i = 0; i < methodCount; i++) {
        
        SEL thisSelector = method_getName(methodList[i]);
        if (thisSelector == selector) {
            
            free(methodList);
            return YES;
        }
    }
    
    free(methodList);
    return NO;
}


#pragma mark -- Debug Method
//static NSArray * ClassMethodsName(Class class)
//{
//    NSMutableArray * methodsArr = [NSMutableArray array];
//
//    unsigned methodCount = 0;
//    Method * methodList = class_copyMethodList(class, &methodCount);
//    for (int i = 0; i < methodCount; i++) {
//
//        [methodsArr addObject: NSStringFromSelector(method_getName(methodList[i]))];
//    }
//    free(methodList);
//
//    return methodsArr;
//}

@end
