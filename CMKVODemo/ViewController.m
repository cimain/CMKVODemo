//
//  ViewController.m
//  CMKVODemo
//
//  Created by ChenMan on 2018/4/19.
//  Copyright © 2018年 cimain. All rights reserved.
//

#import "ViewController.h"
#import "ObservedObject.h"

#import "NSObject+Delegate_KVO.h"
#import "NSObject+Block_KVO.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ObservedObject * object = [ObservedObject new];
    object.observedNum = @111;
    
#pragma mark - Observed By Delegate
//    [object CM_addObserver: self forKey: @"observedNum"];
    
#pragma mark - Observed By Block
    [object CM_addObserver: self forKey: @"observedNum" withBlock: ^(id observedObject, NSString *observedKey, id oldValue, id newValue) {
        NSLog(@"Value had changed yet with observing Block");
        NSLog(@"oldValue---%@",oldValue);
        NSLog(@"newValue---%@",newValue);
    }];
    
    object.observedNum = @888;
}

#pragma mark - ObserverDelegate
-(void)CM_ObserveValueForKeyPath:(NSString *)keyPath ofObject:(id)object oldValue:(id)oldValue newValue:(id)newValue{
    NSLog(@"Value had changed yet with observing Delegate");
    NSLog(@"oldValue---%@",oldValue);
    NSLog(@"newValue---%@",newValue);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
