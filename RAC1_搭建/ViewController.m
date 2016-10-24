//
//  ViewController.m
//  RAC1_搭建
//
//  Created by 吴书敏 on 16/10/21.
//  Copyright © 2016年 littledogboy. All rights reserved.
//

#import "ViewController.h"
#import "RACPlayGround.h"
#import <ReactiveCocoa.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //
    rac_playground();
    // ReactiveCocoa 常见用法
    //  (1) 代替代理
    [[self rac_signalForSelector:@selector(didReceiveMemoryWarning)] subscribeNext:^(id x) {
        NSLog(@"调用了内存警告");
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"内存警告");
    // Dispose of any resources that can be recreated.
}

@end
