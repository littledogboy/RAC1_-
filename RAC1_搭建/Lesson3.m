//
//  Lesson3.m
//  RAC1_搭建
//
//  Created by 吴书敏 on 16/10/25.
//  Copyright © 2016年 littledogboy. All rights reserved.
//

#import "Lesson3.h"
#import <ReactiveCocoa.h>




@interface ExampleViewController ()

@property (nonatomic, strong) UITextField *seachTextField;

@end


@implementation ExampleViewController

void heigherOrderSignal()
{
    RACSignal *signal = [RACSignal return:@1];
    RACSignal *signalHighOrder = [RACSignal return:signal]; // return
    RACSignal *anotherSignal = [signal map:^id(id value) {
        return [RACSignal return:value]; // map return
    }];
}

void subscribeHighOrderSignal()
{
    RACSignal *signal = @[@1, @2, @3].rac_sequence.signal;
    RACSignal *highOrderSignal = [signal map:^id(id value) {
        return [RACSignal return:value];
    }];
    
    // subscribe
    [highOrderSignal subscribeNext:^(RACSignal *signal) {
        [signal subscribeNext:^(id x) {
            // get real value here
        }];
    }];
}

- (void)switchToLatestExample2 {
    RACSignal *seachTextSignal = [self.seachTextField rac_textSignal];
    
    RACSignal *requestSignals = [seachTextSignal map:^id(NSString *searchText) {
        NSString *urlString = [NSString stringWithFormat:@"http://xxx.xxx.xxx/?q=%@", searchText];
        NSURL *url = [NSURL URLWithString:urlString];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        return [NSURLConnection rac_sendAsynchronousRequest:request];
    }];

    requestSignals = [requestSignals switchToLatest];
}

void ifThenElse()
{
    // 类方法
    RACSignal *signalA = nil;
    RACSignal *signalTure = nil;
    RACSignal *signalFalse = nil;
    
    RACSignal *signalB = [RACSignal if:signalA
                                  then:signalTure
                                  else:signalFalse];
    // 内部实现 signalA map  ？ ： switchToLatest
    
    // switchCaseDefault
}

void mapThenFlatten()
{
    // flatten 扁平化
    // flatten:
    RACSignal *signal = @[@1, @2, @3].rac_sequence.signal;
    
    RACSignal *mappedSignal = [[signal map:^id(NSNumber *value) {
        return [[[RACSignal return:value] repeat] take:value.integerValue];
    }] flatten];
    // 1 22 333
    
    // flatten:1 同一时间，只能有一个信号被订阅。 这不就是 concat 。 异步操作，同时只允许1.
    
    // 把 信号降阶的三种方式：
    // 1. switchToLatest 2. flatten (merge) 3. concat (flatten:1)
}


// 信号的高阶操作
// 对值操作 对数量操作 对时间间隔操作 对维度操作
// 思考：改变某一个值的个数  把值/错误/停止互换 缩短/拉长时间间隔

void musicExample()
{
    RACSignal *signal = @[@"♪5", @"♬1", @"♬2", @"♬3", @"♩4"]
    .rac_sequence
    .signal;
    NSDictionary *toneLengthMap = @{@"♩": @0.5,
                                    @"♪": @0.25,
                                    @"♬": @0.125};
    RACSignal *mappedSignal = [[signal map:^id(NSString *value) {
        NSString *tone = [value substringFromIndex:1];
        NSString *length = [value substringToIndex:1];
        NSNumber *toneValue = @(tone.integerValue);
        NSNumber *toneLength = toneLengthMap[length];
        return [[RACSignal return:toneValue]
                concat:[[RACSignal empty]
                        delay: toneLength.doubleValue]];
    }] concat];
}

void valueToError()
{
    RACSignal *signal = @[@1, @2, @3, @0].rac_sequence.signal;
    
    RACSignal *mappedSignal = [[signal map:^id(NSNumber *value) {
        if (value.integerValue == 0) {
            return [RACSignal error:[NSError errorWithDomain:@"0"
                                                        code:0
                                                    userInfo:nil]];
        } else {
            return [RACSignal return:value];
        }
    }] flatten];
}

#pragma mark- flattenMap
void flattenMap()
{
   // 套路： 先 map -》 flatten
    // flattenMap
    // falttenMap 的重要性
    // * 可以用 flattenMap 实现很多信号的转换
    // 支持串行异步操作
    // 满足Monad 部分定义（bind 和return 才完全满足）
    
    RACSignal *signal = @[@1, @2, @3, @0].rac_sequence.signal;
    
    RACSignal *flatten = [signal flattenMap:^RACStream *(id value) {
        return value;
    }];
    
    RACSignal *map = [signal flattenMap:^RACStream *(id value) {
        id anotherValue = value;
        return [RACSignal return:anotherValue];
    }];
    
    RACSignal *filter = [signal flattenMap:^RACStream *(id value) {
        BOOL filter = (value == nil); // filter here!
        return filter ? [RACSignal empty] : [RACSignal return:value];
    }];
}

void serialSyncProcess()
{
    // 异步请求
    NSError *someError = nil;
    RACSignal *signal = [RACSignal return:@"http://xx.com/a"];
    
    RACSignal *getSignal = [signal flattenMap:^RACStream *(NSString *url) {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        return [NSURLConnection rac_sendAsynchronousRequest:request];
    }];
    
    RACSignal *jsonSignal = [getSignal flattenMap:^RACStream *(NSData *data) {
        NSError *error = nil;
        id result = [NSJSONSerialization JSONObjectWithData:data
                                                    options:0
                                                      error:&error];
        return error == nil ? [RACSignal return:result] : [RACSignal error:error];
    }];
    
    RACSignal *getItemSignal = [jsonSignal flattenMap:^RACStream *(NSDictionary *value) {
        if (![value isKindOfClass:[NSDictionary class]] ||
            value[@"data.url"] == nil) {
            return [RACSignal error:someError];
        }
        NSURLRequest *anotherRequest = [NSURLRequest requestWithURL:
                                        [NSURL URLWithString:value[@"data.url"]]];
        return [NSURLConnection rac_sendAsynchronousRequest:anotherRequest];
    }];
}

void subject()
{
    RACSubject *subject = [RACSubject subject];
    
    [subject subscribeNext:^(id x) {
        // a
    } error:^(NSError *error) {
        // b
    } completed:^{
        // c
    }];
    
    [subject sendNext:@1];
    [subject sendNext:@2];
    [subject sendNext:@3];
    
    [subject sendCompleted];
}


@end

