//
//  RACPlayGround.m
//  RAC1_搭建
//
//  Created by 吴书敏 on 16/10/21.
//  Copyright © 2016年 littledogboy. All rights reserved.
//

#import "RACPlayGround.h"
#import <ReactiveCocoa.h>

void test4() {
    
    //
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        [subscriber sendNext:@3];
        [subscriber sendCompleted];
        return nil;
    }];
    
    __block int collection = 0;
    [signal subscribeNext:^(id x) {
        collection += [x intValue];
    }];
    
    [signal aggregateWithStart:@0 reduce:^id(NSNumber * running, NSNumber *next) {
        return @(running.intValue + next.intValue);
    }];
    
    [signal subscribeNext:^(id x) {
        NSLog(@"%@ is the result", x);
    }];
}

void sequence() {
    // RACSteam 数据流
    // RACSequence RACSignal
    // Push-driver 只能被动接受，电视
    // Pull-driver 时间， 循环调用， 看书
    
    // sequence 处理普通的对象
    // signal 传递的是事件： 值事件，
    
    // 其他差异
    
    // RACSequence 为 RACStem 的一个子类
    // 一、 RACSequence 的创建
    // 1. 直接使用 return
    RACSequence *sequence1 = [RACSequence return:@1];
    // 2. sequenceWithHeadBlock
    // 把头 和 身体 拼接到一起
    RACSequence *sequence2 = [RACSequence sequenceWithHeadBlock:^id{
        return @2;
    } tailBlock:^RACSequence *{
        return sequence1;
    }];
    // 3. 桥接
    RACSequence *sequence3 = @[@1, @2, @3].rac_sequence;
    
    // 二、 RACsequence 变换
    // map  concated merged
    
    // 三、 遍历
    //
}

void signalExample() {
    // 
}




