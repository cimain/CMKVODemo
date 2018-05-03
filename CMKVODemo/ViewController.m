//
//  ViewController.m
//  CMKVODemo
//
//  Created by ChenMan on 2018/4/19.
//  Copyright © 2018年 cimain. All rights reserved.
//

#import "ViewController.h"

#import "ViewController.h"
#import "NSObject+CM_KVO.h"
#import "ObservedObject.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ObservedObject * object = [ObservedObject new];
    object.observedNum = @8;
    [object CM_addObserver: self forKey: @"observedNum"];
    object.observedNum = @10;
}

#pragma mark - ObserverDelegate
-(void)CM_ObserveValueForKeyPath:(NSString *)keyPath ofObject:(id)object oldValue:(id)oldValue newValue:(id)newValue{
    NSLog(@"%@", [NSString stringWithFormat:@"%@,%@",oldValue,newValue]);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
