//
//  RACPlayGround.m
//  RAC1_搭建
//
//  Created by 吴书敏 on 16/10/21.
//  Copyright © 2016年 littledogboy. All rights reserved.
//

#import "RACPlayGround.h"
#import <ReactiveCocoa.h>


// 折叠函数
typedef int(^FoldFunction)(int runing, int next);
int flod(int *array, int count, FoldFunction func, int start)
{
    int current = array[0]; // 每次都是数组头一个元素
    int running = func(start, current); // 执行block
    if (count == 1) {
        return running;
    }
    return flod(array + 1, count - 1, func, running); // 本次runing为下一次start
}



void rac_playground()
{
    int arr[] = {1, 2, 3,4 ,5};
    int result = flod(arr, 5, ^int(int runing, int next) {
        return runing + next;
    }, 0);
    
    NSLog(@"%d", result); // 15
    
    
    // 获得一个信号的方式
    // (1) 单元信号
    RACSignal *signal1 = [RACSignal return:@"Some Value"];
    // 订阅时马上发出，并自带一个停止信号
    NSError *error = [[NSError alloc] initWithDomain:@"Something wrong" code:500 userInfo:nil];
    RACSignal *signal2 = [RACSignal error:error]; // 订阅
    RACSignal *signal3 = [RACSignal empty]; // 订阅马上停止
    RACSignal *signal4 = [RACSignal never]; // 永远不会被完成。
    
    // (2) 动态信号
    RACSignal *signal5 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        [subscriber sendError:nil];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            
        }]; // 返回一个disponsable 用来做终止
    }];
    
    // 其他方式 三种
    // （1）Cocoa 桥接 对任何对象都是有效的
    // 非常常用 非常实用
    // 监听 RectiveCocoa 只要执行selector 就发送信号 然后交给 RAC
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    RACSignal *signal6 = [view rac_signalForSelector:@selector(setFrame:)];
    UITextField *tv = [[UITextField alloc] init];
    RACSignal *signal7 = [tv rac_signalForControlEvents:UIControlEventTouchUpInside];
    RACSignal *signal8 = [view rac_willDeallocSignal];
//    RACSignal *signal9 = RACObserve(view, backgroundColor);
    
    
    // (2) 信号变换 signal -》 signal
    RACSignal *signal9 = [signal1 map:^id(NSString *value) {
        return [value substringFromIndex:1];
    }];
    
    // (3) 序列转换
    RACSequence *sequence1 = @[@1, @2, @3].rac_sequence;
    RACSignal *signal10 = sequence1.signal;
    
    
    // 订阅一个信号的方式
    // (1) 订阅方法
//    [signal10 subscribeNext:^(id x) {
//        NSLog(@"next value is %d", [x intValue]);
//    } error:^(NSError *error) {
//        NSLog(@"Get some error: %@", error);
//    } completed:^{
//        NSLog(@"It finished success");
//    }];
    
    // （2）绑定
//    RAC(view, backgroundColor) = signal10;
    
    
    // (3) Cocoa 桥接
    // rac_liftSelector 当所有信号都发送数据的时候调用
//    [view rac_liftSelector:@selector(convertPoint:toView:) withSignals:signal1, signal2, nil];
//    [view rac_liftSelector:@selector(convertRect:toView:) withSignalsFromArray:@[signal3, signal4]];
//    [view rac_liftSelector:@selector(convertRect:toLayer:) withSignalOfArguments:signal5];
    
    // 订阅的过程
    subscribe();
    
    
    // RACSignal
    // 事件类型
    // 值  ：字符 bool int float  tuple  signal
    // 错误：
    // 结束
    // 订阅
    
    
    // 单元信号解析
    /**
     *  retuan
     *  error 订阅时候马上发送一个错误
     *  never 永远不发送停止
     *  empty 只要订阅就发送停止
     */
    
    // 信号的变换和组合
    take();
    sideEffect();
    
    // 信号的各类操作
    // 单个信号的变换
    // 多个信号的组合
    // 高阶操作
}


void subscribe()
{
    // 1. 创建信号
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"dispose");
        }];
    }];
    
    // (2) 信号订阅
    RACDisposable *disposable = [signal subscribeNext:^(id x) {
        NSLog(@"next value is %@", x);
    } error:^(NSError *error) {
        NSLog(@"%@", error);
    } completed:^{
        NSLog(@"completed");
    }];
    
    // 在当前代码中无意义，若是延迟则有意义。
    [disposable dispose];
    
    // 一旦信号被订阅，从进到信号创建时候的block，一旦遇到send 事件直接回调 next error， completed。 完成后return 一个 disposable。当rac发现信号已经停止订阅会马上调用 disposable。
    
    //
    reduceEach();
}

// 元祖
void tuple()
{
    // RACTuplePack 把数据变为tuple
    RACTuple *tuple = RACTuplePack(@1, @"one");
    id first = tuple.fifth;
    id second = tuple.second;
    id last = tuple.last;
    id index1 = tuple[1]; // 下标访问
    // RACTupleUnpack
    // 强转，拿到tuple 的值
    RACTupleUnpack(NSNumber *num, NSString *str) = tuple;
}

void map() {
    RACSignal *signalA = @[@1, @2, @3, @4].rac_sequence.signal;
    RACSignal *newSignal = [signalA map:^id(NSNumber * value) {
        return  @(value.integerValue * 2);
    }];
}

void mapAndMapReplace()
{
    RACSignal *signalA = @[@1, @2, @3, @4].rac_sequence.signal;
    //  每一个都变为8
    RACSignal *signalB = [signalA map:^id(id value) {
        return @8;
    }];
    //
    RACSignal *signalC = [signalA mapReplace:@8];
}

void reduceEach()
{
    // 把序列里面的每一个值 重组计算
    RACTuple *a = RACTuplePack(@1, @2);
    RACTuple *b = RACTuplePack(@2, @3);
    RACTuple *c = RACTuplePack(@3, @5);
    RACSignal *signalA = @[a, b, c].rac_sequence.signal;
    RACSignal *signalB = [signalA reduceEach:^id(NSNumber *first, NSNumber *second){
        return @(first.integerValue + second.integerValue);
    }];
    
    [signalB subscribeNext:^(id x) {
        NSLog(@"%d", [x intValue]);
    }];
}

// not and or

void notAndOr()
{
    RACTuple *tuple = RACTuplePack(@1, @0);
    
    RACSignal *signalA = [RACSignal return:@1];
    RACSignal *signalB = [signalA not]; // 异预算
//    RACSignal *signalC = [tuple and]; // tuple and运算
//    RACSignal *signalD = [tuple or]; // tuple or 运算
    RACSignal *signalE = [signalA reduceApply];
    RACSignal *signalF = [signalA materialize];
    RACSignal *signalG = [signalA dematerialize];
}


#pragma mark- 数量操作
void filter()
{
    // 过滤掉某些值
    RACSignal *signalA = @[@"a", @"b", @"cdef"].rac_sequence.signal;
    RACSignal *signalB = [signalA filter:^BOOL(NSString * value) {
        return value.length > 2;
    }];
}

void ignore()
{
    RACSignal *signalA = @[@1, @2, @3].rac_sequence.signal;
    RACSignal *signalB = [signalA ignore:@1];
    RACSignal *signalC = [signalA ignoreValues]; // 没有值了，只剩下结束事件 或者 错误。
    // 去重
    RACSignal *signalD = [signalA distinctUntilChanged];
}

void take()
{
    RACSignal *signalA = @[@1, @2, @3].rac_sequence.signal;
    RACSignal *signalB = [signalA take:2];
    RACSignal *signalC= [signalA takeLast:1];
}

void startWith()
{
    RACSignal *signalA = @[@"b", @"c", @"e"].rac_sequence.signal;
    RACSignal *signalB = [signalA startWith:@"a"];
}

void sideEffect()
{
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"disposable");
        }];
    }];
    RACSignal *signalB = [signalA map:^id(id value) {
        return value;
    }];
    
    // 信号a 执行 sendNext 之后，subscribeNext之前，会先执行这个block，
    RACSignal *signalC = [signalA doNext:^(NSNumber *x) {
        
        NSLog(@"%d", [x intValue]);
    }];
    
    RACDisposable *disposable = [signalC  subscribeNext:^(id x) {
        NSLog(@"next");
    } completed:^{
        NSLog(@"completed");
    }];
}

void aggregate()
{
    RACSignal *signalA = @[@1, @2, @3, @4].rac_sequence.signal;
    RACSignal *signalB = [signalA aggregateWithStart:@0 reduce:^id(NSNumber *running, NSNumber *next) {
        return @(running.integerValue + next.integerValue);
    }];
    
}

// 扫描
void scan()
{
    RACSignal *signalA = @[@1, @2, @3, @4].rac_sequence.signal;
    RACSignal *signalB = [signalA scanWithStart:@0 reduce:^id(NSNumber  *running, NSNumber *next) {
        return @(running.integerValue + next.integerValue);
    }];
}

void infinitySignal()
{
    RACSignal *repeat1 = [[RACSignal return:@1] repeat];
    RACSignal *signalB = [repeat1 scanWithStart:@0 reduce:^id(NSNumber * running, NSNumber *next) {
        return @(running.integerValue + next.integerValue);
    }];
    
    RACSignal *signalC = [repeat1 scanWithStart:RACTuplePack(@1, @1) reduce:^id(RACTuple *running, id _) {
        NSNumber *next = @([running.first integerValue] + [running.second integerValue]);
        return RACTuplePack(running.second, next);
    }];
}

void delaySignal()
{
    RACSignal *signalA = @[@1, @2 ,@3, @4].rac_sequence.signal;
    RACSignal *signalB = [signalA delay:1];
    
    RACSignal *interval = [[[RACSignal return:@1] delay:1] repeat];
}

#pragma mark- 组合操作
// 拼接
void concatWith()
{
    RACSignal *signalA = @[@1, @2, @3, @4].rac_sequence.signal;
    RACSignal *signalB = @[@6, @7].rac_sequence.signal;
    
    RACSignal *signalC = [signalA concat:signalB];
}

// merge
void merge()
{
    RACSignal *signalA = @[@1, @2, @3, @4].rac_sequence.signal;
    RACSignal *signalB = @[@6, @7].rac_sequence.signal;
    
    {
        RACSignal *signalC = [signalA merge:signalB];
    }
    {
        RACSignal *signalC = [RACSignal merge:@[signalA, signalB]];
    }
    {
        RACSignal *signacC = [RACSignal merge:RACTuplePack(signalA, signalB)];
    }
}

//
void mergeMapReplace()
{
    UIViewController *self = nil;
    RACSignal *appearSignal = [[self rac_signalForSelector:@selector(viewDidAppear:)] mapReplace:@YES];
    RACSignal *disappearSignal = [[self rac_signalForSelector:@selector(viewWillDisappear:)] mapReplace:@NO];
    
    RACSignal *activeSingla = [RACSignal merge:@[appearSignal, disappearSignal]];
}

// 两个信号最后的值 ，结合在一起
void combineLatest()
{
    RACSignal *signalA = @[@1, @2 ,@3, @4, @5].rac_sequence.signal;
    RACSignal *signalB = @[@6, @7].rac_sequence.signal;
    
    {
        RACSignal *signalC = [signalA combineLatestWith:signalB];
    }
    {
        RACSignal *signalC = [RACSignal combineLatest:@[signalA, signalB]];
    }
    {
        RACSignal *signalC = [RACSignal combineLatest:RACTuplePack(signalA, signalB)];
    }
}

// 采样
void sample()
{
    RACSignal *signalA = @[@1, @2, @3].rac_sequence.signal;
    // 采样信号
//    RACSignal *signalB = [signalA ]
}

// takeUntil
void takeUntil()
{
    
}






